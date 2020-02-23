import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:owl/account/db_tables/AccountTable.dart';
import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/contact/db_tables/ContactsTable.dart';
import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/services/CacheService.dart';
import 'package:owl/general/services/FileSystemStorageService.dart';
import 'package:owl/general/services/IStorageService.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/share_room/db_tables/RoomMembershipOperationsTable.dart';
import 'package:owl/share_room/db_tables/ShareItemsTable.dart';
import 'package:owl/share_room/db_tables/ShareRoomsTable.dart';
import 'package:owl/share_room/enums/RoomMembershipOperationType.dart';
import 'package:owl/share_room/enums/ShareItemAckedStatus.dart';
import 'package:owl/share_room/enums/ShareItemStatus.dart';
import 'package:owl/share_room/enums/ShareItemType.dart';
import 'package:owl/share_room/enums/ShareItemUnconfirmedReason.dart';
import 'package:owl/share_room/models/AckModel.dart';
import 'package:owl/share_room/models/RoomMembershipNotificationModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';
import 'package:owl/share_room/models/UserModel.dart';
import 'package:sqflite/sqflite.dart';

class StorageService implements IStorageService {
  final FileSystemStorageService _fileSystemStorageService;
  final CacheService _cacheService;
  final LoggingService _loggingService;

  final String _dbName = 'Owl.db'; // @@TODO: Configuration ?

  Database _db;

  final Completer _dbInitialized = Completer();
  bool _isInitializing = false;

  StorageService(
    this._fileSystemStorageService,
    this._cacheService,
    this._loggingService,
  );

  void _init() async {
    _isInitializing = true;

    // await deleteDatabase(_dbName);
    _db = await openDatabase(_dbName);
    await _db.execute('PRAGMA foreign_keys = ON');

    _createTables();
  }

  void _createTables() async {
    await _db.execute(AccountTable.createTableStatement);
    await _db.execute(ShareRoomsTable.createTableStatement);
    await _db.execute(ShareItemsTable.createTableStatement);
    await _db.execute(RoomMembershipOperationsTable.createTableStatement);
    await _db.execute(ContactsTable.createTableStatement);

    _dbInitialized.complete();
  }

  Future _checkDbInitialized() async {
    if (_dbInitialized.isCompleted) {
      return;
    }

    if (!_isInitializing) {
      _init();
    }

    await _dbInitialized.future;
  }

  @override
  Future createShareRoom(ShareRoomModel shareRoom) async {
    await _checkDbInitialized();

    await _db.insert(ShareRoomsTable.name, {
      ShareRoomsTable.requestIdentifierC: shareRoom.requestIdentifier,
      ShareRoomsTable.identifierC: shareRoom.identifier,
      ShareRoomsTable.nameC: shareRoom.name,
      ShareRoomsTable.isConfirmedC: shareRoom.isConfirmed ? 1 : 0,
      ShareRoomsTable.palsC: json.encode(shareRoom.pals),
      ShareRoomsTable.otherGuyIdC: shareRoom.otherGuyId,
    });
  }

  @override
  Future<List<int>> checkUnseenUsers(List<int> users) async {
    await _checkDbInitialized();

    var s1 = '';
    for (int i = 0; i < users.length; ++i) {
      s1 += i == 0 ? '?' : ', ?';
    }

    List<Map<String, dynamic>> rows = await _db.query(
      ContactsTable.name,
      columns: [
        ContactsTable.userIdC,
      ],
      where: '${ContactsTable.userIdC} IN ($s1)',
      whereArgs: users,
    );

    List<int> seenUsers = [];
    for (var row in rows) {
      seenUsers.add(row[ContactsTable.userIdC]);
    }

    List<int> unseenUsers = [];
    for (int userId in users) {
      if (!seenUsers.contains(userId)) {
        unseenUsers.add(userId);
      }
    }

    return unseenUsers;
  }

  @override
  Future addMyUser(
    int userId,
    Uint8List username,
    Uint8List firebaseUserIdentifier,
  ) async {
    await _checkDbInitialized();

    await _db.insert(ContactsTable.name, {
      ContactsTable.userIdC: userId,
      ContactsTable.usernameC: username,
      ContactsTable.firebaseUserIdentifierC: firebaseUserIdentifier,
      ContactsTable.isMyContactC: 0,
      ContactsTable.isFavoriteC: 0,
    });
  }

  @override
  Future addUsers(List<UserModel> users) async {
    if (users.isEmpty) {
      return;
    }

    await _checkDbInitialized();

    Batch batch = _db.batch();
    for (var user in users) {
      batch.insert(ContactsTable.name, {
        ContactsTable.userIdC: user.id,
        ContactsTable.usernameC: user.username,
        ContactsTable.firebaseUserIdentifierC: user.firebaseUserIdentifier,
        ContactsTable.isMyContactC: 0,
        ContactsTable.isFavoriteC: 0,
      });
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<UserModel> getUser(int userId) async {
    await _checkDbInitialized();

    List<Map<String, dynamic>> rows = await _db.query(
      ContactsTable.name,
      where: '${ContactsTable.userIdC} = ?',
      whereArgs: [userId],
    );

    if (rows.isNotEmpty) {
      var row = rows[0];

      return UserModel(
        id: userId,
        username: row[ContactsTable.usernameC],
        firebaseUserIdentifier: row[ContactsTable.firebaseUserIdentifierC],
      );
    }

    return null;
  }

  @override
  Future<UserModel> getMyUser() async {
    UserModel user = _cacheService.loadUser();
    if (user != null) {
      return user;
    }

    AccountModel account = await loadAccount();

    List<Map<String, dynamic>> rows = await _db.query(
      ContactsTable.name,
      where: '${ContactsTable.userIdC} = ?',
      whereArgs: [account.userId],
    );

    if (rows.isNotEmpty) {
      var row = rows[0];

      user = UserModel(
        id: account.userId,
        username: row[ContactsTable.usernameC],
        firebaseUserIdentifier: row[ContactsTable.firebaseUserIdentifierC],
      );

      user.profilePicture = await _fileSystemStorageService.loadFile(
        'images/${utf8.decode(user.firebaseUserIdentifier)}/profile_picture',
      );

      _cacheService.saveUser(user);

      return user;
    }

    return null;
  }

  @override
  void updateMyUsersProfilePictureInCache(Uint8List profilePicture) {
    UserModel user = _cacheService.loadUser();
    if (user != null) {
      _cacheService.saveUser(
        UserModel(
          id: user.id,
          username: user.username,
          firebaseUserIdentifier: user.firebaseUserIdentifier,
          profilePicture: profilePicture,
        ),
      );
    }
  }

  @override
  Future<List<UserModel>> getMyContacts() async {
    await _checkDbInitialized();

    List<Map<String, dynamic>> rows = await _db.query(
      ContactsTable.name,
      where: '${ContactsTable.isMyContactC} = 1',
    );

    List<UserModel> users = [];
    for (var row in rows) {
      users.add(
        UserModel(
          id: row[ContactsTable.userIdC],
          username: row[ContactsTable.usernameC],
          firebaseUserIdentifier: row[ContactsTable.firebaseUserIdentifierC],
          isFavorite: row[ContactsTable.isFavoriteC] == 1,
        ),
      );
    }

    return users;
  }

  @override
  Future addContact(int userId) async {
    await _checkDbInitialized();

    await _db.update(
      ContactsTable.name,
      {
        ContactsTable.isMyContactC: 1,
      },
      where: '${ContactsTable.userIdC} = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future addContactToFavorites(int userId) async {
    await _checkDbInitialized();

    await _db.update(
      ContactsTable.name,
      {
        ContactsTable.isFavoriteC: 1,
      },
      where: '${ContactsTable.userIdC} = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<List<UserModel>> getFavoriteContacts() async {
    await _checkDbInitialized();

    List<Map<String, dynamic>> rows = await _db.query(
      ContactsTable.name,
      where:
          '${ContactsTable.isMyContactC} = 1 AND ${ContactsTable.isFavoriteC} = 1',
    );

    List<UserModel> users = [];
    for (var row in rows) {
      users.add(
        UserModel(
          id: row[ContactsTable.userIdC],
          username: row[ContactsTable.usernameC],
          firebaseUserIdentifier: row[ContactsTable.firebaseUserIdentifierC],
        ),
      );
    }

    return users;
  }

  @override
  Future<List<ShareItemModel>> confirmShareRoomAndUpdateItems(
    String requestIdentifier,
    Uint8List roomIdentifier,
  ) async {
    await _checkDbInitialized();

    List<ShareItemModel> shareItems = await _db.transaction(
      (txn) async {
        List<Map<String, dynamic>> rows = await txn.query(
          ShareRoomsTable.name,
          columns: [
            ShareRoomsTable.identifierC,
          ],
          where: '${ShareRoomsTable.requestIdentifierC} = ?',
          whereArgs: [requestIdentifier],
        );

        if (rows.isNotEmpty) {
          Uint8List tempRoomIdentifier = rows[0][ShareRoomsTable.identifierC];

          rows = await txn.query(
            ShareItemsTable.name,
            columns: [
              ShareItemsTable.requestIdentifierC,
              ShareItemsTable.typeC,
              ShareItemsTable.contentC,
              ShareItemsTable.imageUrlsC,
            ],
            where:
                "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(tempRoomIdentifier)}'",
            orderBy: '${ShareItemsTable.timeOfCreationC} ASC',
            limit: 32767,
          );

          List<ShareItemModel> shareItems = [];
          for (var row in rows) {
            String imageUrls;

            shareItems.add(
              ShareItemModel(
                requestIdentifier: row[ShareItemsTable.requestIdentifierC],
                roomIdentifier: roomIdentifier,
                type: ShareItemType.values[row[ShareItemsTable.typeC]],
                content: row[ShareItemsTable.contentC],
                imageUrls: (imageUrls = row[ShareItemsTable.imageUrlsC]) != null
                    ? (json.decode(imageUrls) as List<dynamic>)
                        .map((el) => el as String)
                        .toList()
                    : null,
              ),
            );
          }

          if (rows.isNotEmpty) {
            await txn.update(
              ShareItemsTable.name,
              {
                ShareItemsTable.reasonC:
                    ShareItemUnconfirmedReason.InProgress.index,
              },
              where:
                  "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(tempRoomIdentifier)}'",
            );
          }

          await txn.update(
            ShareRoomsTable.name,
            {
              ShareRoomsTable.identifierC: roomIdentifier,
              ShareRoomsTable.isConfirmedC: 1,
            },
            where: '${ShareRoomsTable.requestIdentifierC} = ?',
            whereArgs: [requestIdentifier],
          );

          return shareItems;
        }

        return null;
      },
      exclusive: true,
    );

    return shareItems;
  }

  @override
  Future<bool> checkRoomAndCreateShareItem(ShareItemModel shareItem) async {
    await _checkDbInitialized();

    bool needSend = await _db.transaction(
      (txn) async {
        List<Map<String, dynamic>> rows = await txn.query(
          ShareRoomsTable.name,
          columns: [
            ShareRoomsTable.isConfirmedC,
            ShareRoomsTable.palsC,
          ],
          where:
              "${ShareRoomsTable.identifierC} = x'${hex.encode(shareItem.roomIdentifier)}'",
        );

        if (rows.isNotEmpty) {
          var row = rows[0];
          bool isConfirmedRoom = row[ShareRoomsTable.isConfirmedC] == 1;
          var pals = (json.decode(row[ShareRoomsTable.palsC]) as List<dynamic>)
              .map((el) => el as int)
              .toList();

          Map<String, int> palIdToStatus = {};
          for (int palId in pals) {
            if (palId != shareItem.creatorId) {
              palIdToStatus[palId.toString()] =
                  ShareItemStatus.NotReceived.index;
            }
          }

          // @@??: Use internet time ?
          shareItem.id = await txn.insert(ShareItemsTable.name, {
            ShareItemsTable.requestIdentifierC: shareItem.requestIdentifier,
            ShareItemsTable.roomIdentifierC: shareItem.roomIdentifier,
            ShareItemsTable.creatorIdC: shareItem.creatorId,
            ShareItemsTable.timeOfCreationC: shareItem.timeOfCreation,
            ShareItemsTable.typeC: shareItem.type.index,
            ShareItemsTable.contentC: shareItem.content,
            ShareItemsTable.isConfirmedC: 0,
            ShareItemsTable.reasonC: isConfirmedRoom
                ? ShareItemUnconfirmedReason.InProgress.index
                : ShareItemUnconfirmedReason.RoomNotConfirmed.index,
            ShareItemsTable.statusC: shareItem.status.index,
            ShareItemsTable.palsToExpectAcksFromC: json.encode(palIdToStatus),
            ShareItemsTable.isUploadedToFirebaseC:
                shareItem.type == ShareItemType.Text ? null : 0,
            ShareItemsTable.imageUrlsC: shareItem.imageUrls != null
                ? json.encode(shareItem.imageUrls)
                : null,
          });

          return isConfirmedRoom;
        }

        return false;
      },
      exclusive: true,
    );

    return needSend;
  }

  @override
  Future confirmUploadingToFirebase(String requestIdentifier) async {
    await _checkDbInitialized();

    await _db.update(
      ShareItemsTable.name,
      {
        ShareItemsTable.isUploadedToFirebaseC: 1,
      },
      where: '${ShareItemsTable.requestIdentifierC} = ?',
      whereArgs: [requestIdentifier],
    );
  }

  @override
  Future<ShareRoomModel> getShareRoom(Uint8List roomIdentifier) async {
    await _checkDbInitialized();

    List<Map<String, dynamic>> rows = await _db.query(
      ShareRoomsTable.name,
      columns: [
        ShareRoomsTable.palsC,
        ShareRoomsTable.isConfirmedC,
      ],
      where: '${ShareRoomsTable.identifierC} = ?',
      whereArgs: [roomIdentifier],
    );

    if (rows.isNotEmpty) {
      var row = rows[0];
      return ShareRoomModel(
        pals: (json.decode(row[ShareRoomsTable.palsC]) as List<dynamic>)
            .map((el) => el as int)
            .toList(),
        isConfirmed: row[ShareRoomsTable.isConfirmedC] == 1,
      );
    }

    return null;
  }

  @override
  Future createShareItem(ShareItemModel shareItem) async {
    await _checkDbInitialized();

    await _db.insert(ShareItemsTable.name, {
      ShareItemsTable.roomIdentifierC: shareItem.roomIdentifier,
      ShareItemsTable.creatorIdC: shareItem.creatorId,
      ShareItemsTable.timeOfCreationC: shareItem.timeOfCreation,
      ShareItemsTable.typeC: shareItem.type.index,
      ShareItemsTable.contentC: shareItem.content,
      ShareItemsTable.isConfirmedC: 1,
      ShareItemsTable.ackedStatusC: ShareItemAckedStatus.None.index,
      ShareItemsTable.imageUrlsC:
          shareItem.imageUrls != null ? json.encode(shareItem.imageUrls) : null,
    });
  }

  @override
  Future confirmShareItem(String requestIdentifier, int timeOfCreation) async {
    await _checkDbInitialized();

    await _db.update(
      ShareItemsTable.name,
      {
        ShareItemsTable.timeOfCreationC: timeOfCreation,
        ShareItemsTable.isConfirmedC: 1,
        ShareItemsTable.reasonC: null,
      },
      where: '${ShareItemsTable.requestIdentifierC} = ?',
      whereArgs: [requestIdentifier],
    );
  }

  @override
  Future changeItemsUnconfirmedReason(
    String requestIdentifier,
    ShareItemUnconfirmedReason reason,
  ) async {
    await _checkDbInitialized();

    await _db.update(
      ShareItemsTable.name,
      {
        ShareItemsTable.reasonC: reason.index,
      },
      where: '${ShareItemsTable.requestIdentifierC} = ?',
      whereArgs: [requestIdentifier],
    );
  }

  @override
  Future changeItemsAckedStatuses(Iterable<ShareItemModel> shareItems) async {
    await _checkDbInitialized();

    Batch batch = _db.batch();
    for (var shareItem in shareItems) {
      batch.update(
        ShareItemsTable.name,
        {
          ShareItemsTable.ackedStatusC: ShareItemAckedStatus.AckedRead.index,
        },
        where:
            "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(shareItem.roomIdentifier)}' AND ${ShareItemsTable.timeOfCreationC} = ?",
        whereArgs: [shareItem.timeOfCreation],
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future changeItemsAckedStatus(
    Uint8List roomIdentifier,
    int timeOfCreation,
    ShareItemAckedStatus ackedStatus,
  ) async {
    await _checkDbInitialized();

    await _db.update(
      ShareItemsTable.name,
      {
        ShareItemsTable.ackedStatusC: ackedStatus.index,
      },
      where:
          "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(roomIdentifier)}' AND ${ShareItemsTable.timeOfCreationC} = ?",
      whereArgs: [timeOfCreation],
    );
  }

  @override
  Future<List<ShareItemModel>> getAllUnconfirmedAcks() async {
    await _checkDbInitialized();

    List<Map<String, dynamic>> rows = await _db.query(
      ShareItemsTable.name,
      columns: [
        ShareItemsTable.roomIdentifierC,
        ShareItemsTable.timeOfCreationC,
      ],
      where:
          '${ShareItemsTable.ackedStatusC} = ${ShareItemAckedStatus.None.index}',
      orderBy: '${ShareItemsTable.timeOfCreationC} DESC',
      limit: 32767,
    );

    List<ShareItemModel> shareItems = [];
    for (var row in rows) {
      shareItems.add(
        ShareItemModel(
          roomIdentifier: row[ShareItemsTable.roomIdentifierC],
          timeOfCreation: row[ShareItemsTable.timeOfCreationC],
        ),
      );
    }

    return shareItems;
  }

  @override
  Future confirmAcks(List<ShareItemModel> acks) async {
    if (acks.isEmpty) {
      return;
    }

    await _checkDbInitialized();

    Batch batch = _db.batch();
    for (var ack in acks) {
      batch.update(
        ShareItemsTable.name,
        {
          ShareItemsTable.ackedStatusC: ShareItemAckedStatus.AckedReceive.index,
        },
        where:
            "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(ack.roomIdentifier)}' AND ${ShareItemsTable.timeOfCreationC} = ?",
        whereArgs: [ack.timeOfCreation],
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future createShareRooms(List<ShareRoomModel> shareRooms) async {
    if (shareRooms.isEmpty) {
      return;
    }

    await _checkDbInitialized();

    var batch = _db.batch();
    for (var shareRoom in shareRooms) {
      batch.insert(ShareRoomsTable.name, {
        ShareRoomsTable.requestIdentifierC: shareRoom.requestIdentifier,
        ShareRoomsTable.identifierC: shareRoom.identifier,
        ShareRoomsTable.nameC: shareRoom.name,
        ShareRoomsTable.palsC: json.encode(shareRoom.pals),
        ShareRoomsTable.isConfirmedC: shareRoom.isConfirmed ? 1 : 0,
      });
    }

    await batch.commit(noResult: true);
  }

  @override
  Future createShareItems(List<ShareItemModel> shareItems) async {
    if (shareItems.isEmpty) {
      return;
    }

    await _checkDbInitialized();

    Batch batch = _db.batch();
    for (var shareItem in shareItems) {
      batch.insert(ShareItemsTable.name, {
        ShareItemsTable.roomIdentifierC: shareItem.roomIdentifier,
        ShareItemsTable.creatorIdC: shareItem.creatorId,
        ShareItemsTable.timeOfCreationC: shareItem.timeOfCreation,
        ShareItemsTable.typeC: shareItem.type.index,
        ShareItemsTable.contentC: shareItem.content,
        ShareItemsTable.isConfirmedC: 1,
        ShareItemsTable.ackedStatusC: ShareItemAckedStatus.None.index,
        ShareItemsTable.imageUrlsC: shareItem.imageUrls != null
            ? json.encode(shareItem.imageUrls)
            : null,
      });
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<List<ShareRoomModel>> getAllUnconfirmedRooms() async {
    await _checkDbInitialized();

    // @@NOTE: Here we retrieve both rooms created by us and someone else,
    // which is technically not correct since we are only interested in rooms created by us.
    // But this is fine, because only rooms created by us can be unconfirmed.
    List<Map<String, dynamic>> rows = await _db.query(
      ShareRoomsTable.name,
      columns: [
        ShareRoomsTable.requestIdentifierC,
        ShareRoomsTable.nameC,
        ShareRoomsTable.palsC,
      ],
      where: '${ShareRoomsTable.isConfirmedC} = 0',
      limit: 255,
    );

    List<ShareRoomModel> shareRooms = [];
    for (var row in rows) {
      shareRooms.add(
        ShareRoomModel(
          requestIdentifier: row[ShareRoomsTable.requestIdentifierC],
          name: row[ShareRoomsTable.nameC],
          pals: (json.decode(row[ShareRoomsTable.palsC]) as List<dynamic>)
              .map((el) => el as int)
              .toList(),
        ),
      );
    }

    return shareRooms;
  }

  @override
  Future<List<ShareItemModel>> getAllUnconfirmedItemsWithReasons(
    List<ShareItemUnconfirmedReason> reasons,
  ) async {
    await _checkDbInitialized();

    var s1 = '';
    for (int i = 0; i < reasons.length; ++i) {
      s1 += i == 0 ? '?' : ', ?';
    }

    // @@NOTE: Here we retrieve both items created by us and someone else,
    // which is technically not correct since we are only interested in items created by us.
    // But this is fine, because only items created by us can be unconfirmed.
    List<Map<String, dynamic>> rows = await _db.query(
      ShareItemsTable.name,
      columns: [
        ShareItemsTable.requestIdentifierC,
        ShareItemsTable.roomIdentifierC,
        ShareItemsTable.typeC,
        ShareItemsTable.contentC,
        ShareItemsTable.isUploadedToFirebaseC,
        ShareItemsTable.imageUrlsC,
      ],
      where:
          '${ShareItemsTable.isConfirmedC} = 0 AND ${ShareItemsTable.reasonC} IN ($s1)',
      whereArgs: reasons.map((reason) => reason.index).toList(),
      orderBy: '${ShareItemsTable.timeOfCreationC} ASC',
      limit: 32767,
    );

    List<ShareItemModel> shareItems = [];
    for (var row in rows) {
      int isUploadedToFirebase = row[ShareItemsTable.isUploadedToFirebaseC];
      String imageUrls;

      shareItems.add(
        ShareItemModel(
          requestIdentifier: row[ShareItemsTable.requestIdentifierC],
          roomIdentifier: row[ShareItemsTable.roomIdentifierC],
          type: ShareItemType.values[row[ShareItemsTable.typeC]],
          content: row[ShareItemsTable.contentC],
          isUploadedToFirebase:
              isUploadedToFirebase != null ? isUploadedToFirebase == 1 : null,
          imageUrls: (imageUrls = row[ShareItemsTable.imageUrlsC]) != null
              ? (json.decode(imageUrls) as List<dynamic>)
                  .map((el) => el as String)
                  .toList()
              : null,
        ),
      );
    }

    return shareItems;
  }

  @override
  Future<List<ShareRoomModel>> getShareRoomsWithLatestItem({
    bool confirmedOnly,
  }) async {
    await _checkDbInitialized();

    if (!confirmedOnly) {
      List<Map<String, dynamic>> rows = await _db.rawQuery(
        ShareItemsTable.getAllRoomsWithLatestItemStatement,
      );
      // @@NOTE: Empty rooms will be last.
      List<ShareRoomModel> shareRooms = [];
      for (var row in rows) {
        int creatorId = row[ShareItemsTable.creatorIdC];
        Uint8List otherGuyUsername = row[ContactsTable.usernameC];
        Uint8List otherGuyFirebaseUserIdentifier =
            row[ContactsTable.firebaseUserIdentifierC];

        shareRooms.add(
          ShareRoomModel(
            identifier: row[ShareRoomsTable.identifierC],
            name: otherGuyUsername != null
                ? utf8.decode(otherGuyUsername)
                : row[ShareRoomsTable.nameC],
            unreadCount: row[ShareItemsTable.unreadCountTC],
            otherGuy: otherGuyFirebaseUserIdentifier != null
                ? UserModel(
                    firebaseUserIdentifier: otherGuyFirebaseUserIdentifier,
                  )
                : null,
            latestItem: creatorId == null
                ? null
                : ShareItemModel(
                    creatorId: creatorId,
                    timeOfCreation: row[ShareItemsTable.timeOfCreationC],
                    type: ShareItemType.values[row[ShareItemsTable.typeC]],
                    content: row[ShareItemsTable.contentC],
                    ackedStatus: row[ShareItemsTable.ackedStatusC] != null
                        ? ShareItemAckedStatus
                            .values[row[ShareItemsTable.ackedStatusC]]
                        : null,
                  ),
          ),
        );
      }

      return shareRooms;
    }

    List<Map<String, dynamic>> rows = await _db.rawQuery(
      ShareItemsTable
          .getConfirmedRoomsWithLatestConfirmedTimeOfCreationStatement,
    );

    List<ShareRoomModel> shareRooms = [];
    for (var row in rows) {
      shareRooms.add(
        ShareRoomModel(
          identifier: row[ShareRoomsTable.identifierC],
          latestItem: ShareItemModel(
            timeOfCreation: row[ShareItemsTable.timeOfCreationC],
          ),
        ),
      );
    }

    return shareRooms;
  }

  @override
  Future<List<List<ShareItemModel>>> confirmShareRoomsAndUpdateItems(
    List<ShareRoomModel> shareRooms,
  ) async {
    if (shareRooms.isEmpty) {
      return null;
    }

    var futures = List<Future<List<ShareItemModel>>>();
    for (var shareRoom in shareRooms) {
      futures.add(
        confirmShareRoomAndUpdateItems(
          shareRoom.requestIdentifier,
          shareRoom.identifier,
        ),
      );
    }

    return await Future.wait(futures);
  }

  @override
  Future confirmShareItems(List<ShareItemModel> shareItems) async {
    if (shareItems.isEmpty) {
      return;
    }

    await _checkDbInitialized();

    Batch batch = _db.batch();
    for (var shareItem in shareItems) {
      batch.update(
        ShareItemsTable.name,
        {
          ShareItemsTable.timeOfCreationC: shareItem.timeOfCreation,
          ShareItemsTable.isConfirmedC: 1,
          ShareItemsTable.reasonC: null,
        },
        where: '${ShareItemsTable.requestIdentifierC} = ?',
        whereArgs: [shareItem.requestIdentifier],
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future applyRoomMembershipNotifications(
    List<RoomMembershipNotificationModel> notifications,
  ) async {
    if (notifications.isEmpty) {
      return;
    }

    List<Future> futures = [];
    for (var notification in notifications) {
      futures.add(applyRoomMembershipNotification(notification));
    }

    await Future.wait(futures);
  }

  @override
  Future applyRoomMembershipNotification(
    RoomMembershipNotificationModel notification,
  ) async {
    await _checkDbInitialized();

    await _db.transaction(
      (txn) async {
        List<Map<String, dynamic>> rows = await txn.query(
          ShareRoomsTable.name,
          columns: [
            ShareRoomsTable.palsC,
          ],
          where:
              "${ShareRoomsTable.identifierC} = x'${hex.encode(notification.roomIdentifier)}'",
        );

        if (rows.isNotEmpty) {
          var pals =
              (json.decode(rows[0][ShareRoomsTable.palsC]) as List<dynamic>)
                  .map((el) => el as int)
                  .toList();

          if (notification.operationType == RoomMembershipOperationType.Add) {
            for (int palId in notification.pals) {
              if (!pals.contains(palId)) {
                pals.add(palId);
              }
            }
          } else {
            pals.remove(notification.pals[0]);
          }

          await txn.update(
            ShareRoomsTable.name,
            {
              ShareRoomsTable.palsC: json.encode(pals),
            },
            where:
                "${ShareRoomsTable.identifierC} = x'${hex.encode(notification.roomIdentifier)}'",
          );
        }
      },
      exclusive: true,
    );
  }

  @override
  Future ackShareItems(List<AckModel> acks) async {
    if (acks.isEmpty) {
      return;
    }

    await _checkDbInitialized();

    List<Future> futures = [];
    for (var ack in acks) {
      futures.add(_ackShareItem(ack));
    }

    await Future.wait(futures);
  }

  Future _ackShareItem(AckModel ack) async {
    await _db.transaction(
      (txn) async {
        List<Map<String, dynamic>> rows = await txn.query(
          ShareItemsTable.name,
          columns: [
            ShareItemsTable.palsToExpectAcksFromC,
          ],
          where:
              "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(ack.roomIdentifier)}' AND ${ShareItemsTable.timeOfCreationC} = ?",
          whereArgs: [ack.timeOfCreation],
        );

        if (rows.isNotEmpty) {
          String jsonString = rows[0][ShareItemsTable.palsToExpectAcksFromC];
          if (jsonString != null) {
            // '{"palId1": 1, "palId2": 0, ...}'
            Map<String, dynamic> map = json.decode(jsonString);
            Map<String, int> map2 = {};
            bool atLeastOneNotReceived = false;
            bool atLeastOneNotRead = false;
            for (String key in map.keys) {
              var palId = int.parse(key);
              if (ack.notReceivedPals.contains(palId)) {
                map2[key] = ShareItemStatus.NotReceived.index;
                atLeastOneNotReceived = true;
              } else if (ack.notReadPals.contains(palId)) {
                map2[key] = ShareItemStatus.ReceivedNotRead.index;
                atLeastOneNotRead = true;
              } else {
                map2[key] = ShareItemStatus.Read.index;
              }
            }

            await txn.update(
              ShareItemsTable.name,
              {
                ShareItemsTable.statusC: atLeastOneNotReceived
                    ? ShareItemStatus.NotReceived.index
                    : (atLeastOneNotRead
                        ? ShareItemStatus.ReceivedNotRead.index
                        : ShareItemStatus.Read.index),
                ShareItemsTable.palsToExpectAcksFromC:
                    atLeastOneNotReceived || atLeastOneNotRead
                        ? json.encode(map2)
                        : null,
              },
              where:
                  "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(ack.roomIdentifier)}' AND ${ShareItemsTable.timeOfCreationC} = ?",
              whereArgs: [ack.timeOfCreation],
            );
          }
        }
      },
      exclusive: true,
    );
  }

  @override
  Future<List<ShareItemStatus>> ackReadShareItems(List<AckModel> acks) {
    List<Future<ShareItemStatus>> futures = [];
    for (var ack in acks) {
      futures.add(ackShareItem(ack));
    }

    return Future.wait(futures);
  }

  @override
  Future<ShareItemStatus> ackShareItem(AckModel ack) async {
    await _checkDbInitialized();

    ShareItemStatus status = await _db.transaction(
      (txn) async {
        List<Map<String, dynamic>> rows = await txn.query(
          ShareItemsTable.name,
          columns: [
            ShareItemsTable.palsToExpectAcksFromC,
          ],
          where:
              "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(ack.roomIdentifier)}' AND ${ShareItemsTable.timeOfCreationC} = ?",
          whereArgs: [ack.timeOfCreation],
        );

        if (rows.isNotEmpty) {
          String jsonString = rows[0][ShareItemsTable.palsToExpectAcksFromC];
          if (jsonString != null) {
            // '{"palId1": 1, "palId2": 0, ...}'
            Map<String, dynamic> map = json.decode(jsonString);
            var key = ack.palId.toString();
            if (map.containsKey(key)) {
              map[key] = ack.messageCode == MessageCode.AckReceive
                  ? ShareItemStatus.ReceivedNotRead.index
                  : ShareItemStatus.Read.index;

              bool atLeastOneNotReceived = false;
              bool atLeastOneNotRead = false;
              for (int value in map.values) {
                var status = ShareItemStatus.values[value];
                if (status == ShareItemStatus.NotReceived) {
                  atLeastOneNotReceived = true;
                } else if (status == ShareItemStatus.ReceivedNotRead) {
                  atLeastOneNotRead = true;
                }
              }

              ShareItemStatus status = atLeastOneNotReceived
                  ? ShareItemStatus.NotReceived
                  : (atLeastOneNotRead
                      ? ShareItemStatus.ReceivedNotRead
                      : ShareItemStatus.Read);

              await txn.update(
                ShareItemsTable.name,
                {
                  ShareItemsTable.statusC: status.index,
                  ShareItemsTable.palsToExpectAcksFromC:
                      atLeastOneNotReceived || atLeastOneNotRead
                          ? json.encode(map)
                          : null,
                },
                where:
                    "${ShareItemsTable.roomIdentifierC} = x'${hex.encode(ack.roomIdentifier)}' AND ${ShareItemsTable.timeOfCreationC} = ?",
                whereArgs: [ack.timeOfCreation],
              );

              return status;
            }
          }
        }

        return null;
      },
      exclusive: true,
    );

    return status;
  }

  @override
  Future<List<ShareItemModel>> getShareItemsFromRoom(
    Uint8List roomIdentifier, {
    bool initial,
    int offset,
  }) async {
    await _checkDbInitialized();

    List<Map<String, dynamic>> rows;
    if (initial) {
      rows = await _db.transaction(
        (txn) async {
          var query = '''
            SELECT COUNT(${ShareItemsTable.timeOfCreationC}) ${ShareItemsTable.itemCountTC}
            FROM ${ShareItemsTable.name}
            WHERE
              ${ShareItemsTable.roomIdentifierC} = x'${hex.encode(roomIdentifier)}'
              AND
              ${ShareItemsTable.timeOfCreationC} >= (
                SELECT MIN(${ShareItemsTable.timeOfCreationC}) -- oldest unread item's time of creation
                FROM ${ShareItemsTable.name}
                WHERE
                  ${ShareItemsTable.roomIdentifierC} = x'${hex.encode(roomIdentifier)}'
                  AND
                  ${ShareItemsTable.ackedStatusC} IN (
                    ${ShareItemAckedStatus.None.index},
                    ${ShareItemAckedStatus.AckedReceive.index}
                  )
              )
          ''';

          List<Map<String, dynamic>> rows = await txn.rawQuery(query);
          // count will be zero if room is empty or there are no unread items
          int count = rows[0][ShareItemsTable.itemCountTC];
          if (count < 50) {
            // @@TODO: Config
            count = 50;
          }

          query = '''
            SELECT
              si.${ShareItemsTable.roomIdentifierC},
              si.${ShareItemsTable.creatorIdC},
              si.${ShareItemsTable.timeOfCreationC},
              si.${ShareItemsTable.typeC},
              si.${ShareItemsTable.contentC},
              si.${ShareItemsTable.isConfirmedC},
              si.${ShareItemsTable.statusC},
              si.${ShareItemsTable.ackedStatusC},
              si.${ShareItemsTable.imageUrlsC},
              c.${ContactsTable.usernameC}
            FROM ${ShareItemsTable.name} AS si LEFT JOIN ${ContactsTable.name} AS c
              ON (si.${ShareItemsTable.creatorIdC} = c.${ContactsTable.userIdC})
            WHERE si.${ShareItemsTable.roomIdentifierC} = x'${hex.encode(roomIdentifier)}'
            ORDER BY si.${ShareItemsTable.timeOfCreationC} DESC
            LIMIT $count
          ''';

          return await txn.rawQuery(query);
        },
        exclusive: true,
      );
    } else {
      var query = '''
        SELECT
          si.${ShareItemsTable.roomIdentifierC},
          si.${ShareItemsTable.creatorIdC},
          si.${ShareItemsTable.timeOfCreationC},
          si.${ShareItemsTable.typeC},
          si.${ShareItemsTable.contentC},
          si.${ShareItemsTable.isConfirmedC},
          si.${ShareItemsTable.statusC},
          si.${ShareItemsTable.ackedStatusC},
          si.${ShareItemsTable.imageUrlsC},
          c.${ContactsTable.usernameC}
        FROM ${ShareItemsTable.name} AS si LEFT JOIN ${ContactsTable.name} AS c
          ON (si.${ShareItemsTable.creatorIdC} = c.${ContactsTable.userIdC})
        WHERE si.${ShareItemsTable.roomIdentifierC} = x'${hex.encode(roomIdentifier)}'
        ORDER BY si.${ShareItemsTable.timeOfCreationC} DESC
        LIMIT 50
        OFFSET $offset
      ''';

      rows = await _db.rawQuery(query);
    }

    List<ShareItemModel> shareItems = [];
    for (var row in rows) {
      Uint8List username = row[ContactsTable.usernameC];
      String imageUrls;

      shareItems.add(
        ShareItemModel(
          roomIdentifier: row[ShareItemsTable.roomIdentifierC],
          creatorId: row[ShareItemsTable.creatorIdC],
          timeOfCreation: row[ShareItemsTable.timeOfCreationC],
          type: ShareItemType.values[row[ShareItemsTable.typeC]],
          content: row[ShareItemsTable.contentC],
          isConfirmed: row[ShareItemsTable.isConfirmedC] == 1,
          status: row[ShareItemsTable.statusC] != null
              ? ShareItemStatus.values[row[ShareItemsTable.statusC]]
              : null,
          ackedStatus: row[ShareItemsTable.ackedStatusC] != null
              ? ShareItemAckedStatus.values[row[ShareItemsTable.ackedStatusC]]
              : null,
          imageUrls: (imageUrls = row[ShareItemsTable.imageUrlsC]) != null
              ? (json.decode(imageUrls) as List<dynamic>)
                  .map((el) => el as String)
                  .toList()
              : null,
          creator: username != null ? UserModel(username: username) : null,
        ),
      );
    }

    // @@NOTE:
    // We retrieve items from newest to oldest specifying limit and offset,
    // but we store items in cache in a reverse order, because then we will be
    // able to append newly arrived item, instead of inserting it at the beginning
    // of the list and shifting all the items.
    shareItems = shareItems.reversed.toList();

    await _loadThumbnailsFromFileSystem(shareItems);

    _cacheService.addShareItems(shareItems);
    shareItems = _cacheService.getShareItems();

    return shareItems;
  }

  @override
  List<ShareItemModel> addShareItemToCache(ShareItemModel shareItem) {
    _cacheService.addShareItem(shareItem);
    return _cacheService.getShareItems();
  }

  @override
  List<ShareItemModel> updateShareItemsStatusInCache(
    AckModel ack,
    ShareItemStatus status,
  ) {
    _cacheService.updateShareItemsStatus(ack, status);
    return _cacheService.getShareItems();
  }

  @override
  List<ShareItemModel> updateShareItemsStatusesInCache(
    List<AckModel> acks,
    List<ShareItemStatus> statuses,
  ) {
    _cacheService.updateShareItemsStatuses(acks, statuses);
    return _cacheService.getShareItems();
  }

  @override
  List<ShareItemModel> updateShareItemsTimeInCache(
    int shareItemId,
    int timeOfCreation,
  ) {
    _cacheService.updateShareItemsTime(shareItemId, timeOfCreation);
    return _cacheService.getShareItems();
  }

  @override
  void resetShareItemsCache() {
    _cacheService.resetShareItems();
  }

  Future _loadThumbnailsFromFileSystem(List<ShareItemModel> shareItems) async {
    List<Future<List<Uint8List>>> futures = [];
    for (var shareItem in shareItems) {
      if (shareItem.type == ShareItemType.Images ||
          shareItem.type == ShareItemType.TextImages) {
        List<Future<Uint8List>> loadThumbnailFutures = [];
        for (String filePath in shareItem.imageUrls) {
          loadThumbnailFutures.add(
            _fileSystemStorageService.loadFile('${filePath}_thumbnail'),
          );
        }
        futures.add(Future.wait(loadThumbnailFutures));
      }
    }

    if (futures.isNotEmpty) {
      List<List<Uint8List>> thumbnailsPerItem = await Future.wait(futures);

      int i = 0;
      for (var shareItem in shareItems) {
        if (shareItem.type == ShareItemType.Images ||
            shareItem.type == ShareItemType.TextImages) {
          shareItem.thumbnails = thumbnailsPerItem[i++];
        }
      }
    }
  }

  @override
  Future createRoomMembershipNotification(
    String requestIdentifier,
    Uint8List roomIdentifier, {
    List<int> pals,
  }) async {
    await _checkDbInitialized();

    await _db.insert(RoomMembershipOperationsTable.name, {
      RoomMembershipOperationsTable.requestIdentifierC: requestIdentifier,
      RoomMembershipOperationsTable.roomIdentifierC: roomIdentifier,
      RoomMembershipOperationsTable.palsC: pals,
    });
  }

  @override
  Future confirmRoomMembershipOperations(
    List<RoomMembershipNotificationModel> operations,
  ) async {
    if (operations.isEmpty) {
      return;
    }

    List<Future> futures = [];

    for (var operation in operations) {
      futures.add(
        confirmRoomMembershipOperation(
          operation.requestIdentifier,
          operation.roomIdentifier,
          pals: operation.pals,
        ),
      );
    }

    await Future.wait(futures);
  }

  @override
  Future confirmRoomMembershipOperation(
    String requestIdentifier,
    Uint8List roomIdentifier, {
    List<int> pals,
  }) async {
    await _checkDbInitialized();

    await _db.transaction(
      (txn) async {
        await txn.delete(
          RoomMembershipOperationsTable.name,
          where: '${RoomMembershipOperationsTable.requestIdentifierC} = ?',
          whereArgs: [requestIdentifier],
        );

        if (pals != null) {
          List<Map<String, dynamic>> rows = await txn.query(
            ShareRoomsTable.name,
            columns: [
              ShareRoomsTable.palsC,
            ],
            where:
                "${ShareRoomsTable.identifierC} = x'${hex.encode(roomIdentifier)}'",
          );

          if (rows.isNotEmpty) {
            var currentPals =
                (json.decode(rows[0][ShareRoomsTable.palsC]) as List<dynamic>)
                    .map((el) => el as int)
                    .toList();

            for (int palId in pals) {
              if (!currentPals.contains(palId)) {
                currentPals.add(palId);
              }
            }

            await txn.update(
              ShareRoomsTable.name,
              {
                ShareRoomsTable.palsC: json.encode(currentPals),
              },
              where:
                  "${ShareRoomsTable.identifierC} = x'${hex.encode(roomIdentifier)}'",
            );
          }
        } else {
          await txn.delete(
            ShareRoomsTable.name,
            where:
                "${ShareRoomsTable.identifierC} = x'${hex.encode(roomIdentifier)}'",
          );
        }
      },
      exclusive: true,
    );
  }

  @override
  Future<List<RoomMembershipNotificationModel>>
      getAllUnconfirmedRoomMembershipOperations() async {
    await _checkDbInitialized();

    List<Map<String, dynamic>> rows = await _db.query(
      RoomMembershipOperationsTable.name,
      limit: 255,
    );

    List<RoomMembershipNotificationModel> notifications = [];
    for (var row in rows) {
      String pals;
      notifications.add(
        RoomMembershipNotificationModel(
          requestIdentifier:
              row[RoomMembershipOperationsTable.requestIdentifierC],
          roomIdentifier: row[RoomMembershipOperationsTable.roomIdentifierC],
          pals: (pals = row[RoomMembershipOperationsTable.palsC]) != null
              ? (json.decode(pals) as List<dynamic>)
                  .map((el) => el as int)
                  .toList()
              : null,
        ),
      );
    }

    return notifications;
  }

  @override
  Future<AccountModel> loadAccount() async {
    AccountModel account = _cacheService.loadAccount();
    if (account != null) {
      return account;
    }

    await _checkDbInitialized();

    List<Map<String, dynamic>> rows = await _db.query(AccountTable.name);

    if (rows.isNotEmpty) {
      var row = rows[0];
      account = AccountModel(
        email: row[AccountTable.emailC],
        username: row[AccountTable.usernameC],
        password: row[AccountTable.passwordC],
        userIdentifier: row[AccountTable.userIdentifierC],
        userId: row[AccountTable.userIdC],
        isConfirmed: row[AccountTable.isConfirmedC] == 1,
        sessionIdentifier: row[AccountTable.sessionIdentifierC],
      );

      _cacheService.saveAccount(account);
    }

    return account;
  }

  @override
  Future createAccount(
    String email,
    String username,
    String password,
    Uint8List userIdentifier,
  ) async {
    await _checkDbInitialized();

    await _db.insert(AccountTable.name, {
      AccountTable.emailC: email,
      AccountTable.usernameC: username,
      AccountTable.passwordC: password,
      AccountTable.userIdentifierC: userIdentifier,
      AccountTable.isConfirmedC: 0,
    });

    _cacheService.saveAccount(
      AccountModel(
        email: email,
        username: username,
        password: password,
        userIdentifier: userIdentifier,
        isConfirmed: false,
      ),
    );
  }

  @override
  Future confirmAccount(Uint8List sessionIdentifier, int userId) async {
    await _checkDbInitialized();

    await _db.update(AccountTable.name, {
      AccountTable.userIdC: userId,
      AccountTable.isConfirmedC: 1,
      AccountTable.sessionIdentifierC: sessionIdentifier,
    });

    AccountModel account = _cacheService.loadAccount();

    _cacheService.saveAccount(
      AccountModel(
        email: account.email,
        username: account.username,
        password: account.password,
        userIdentifier: account.userIdentifier,
        userId: userId,
        isConfirmed: true,
        sessionIdentifier: sessionIdentifier,
      ),
    );
  }
}
