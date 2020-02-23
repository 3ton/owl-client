import 'dart:convert';
import 'dart:typed_data';

import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/account/services/AccountService.dart';
import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/contact/services/ContactService.dart';
import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/general/services/FileSystemStorageService.dart';
import 'package:owl/general/services/IImageStorageService.dart';
import 'package:owl/general/services/IMessageService.dart';
import 'package:owl/general/services/ThumbnailGeneratorService.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/share_room/enums/RoomMembershipOperationType.dart';
import 'package:owl/share_room/enums/ShareItemAckedStatus.dart';
import 'package:owl/share_room/enums/ShareItemStatus.dart';
import 'package:owl/share_room/enums/ShareItemType.dart';
import 'package:owl/share_room/enums/ShareItemUnconfirmedReason.dart';
import 'package:owl/share_room/events/events.dart';
import 'package:owl/share_room/messages/AckReadMessage.dart';
import 'package:owl/share_room/messages/AckReceiveMessage.dart';
import 'package:owl/share_room/messages/AckReceiveReadMessage.dart';
import 'package:owl/share_room/messages/AckRoomMembershipOperationMessage.dart';
import 'package:owl/share_room/messages/CreateShareItemMessage.dart';
import 'package:owl/share_room/messages/CreateShareRoomMessage.dart';
import 'package:owl/share_room/messages/DeleteAcksMessage.dart';
import 'package:owl/share_room/messages/IsTypingMessage.dart';
import 'package:owl/share_room/messages/JoinMessage.dart';
import 'package:owl/share_room/messages/LeaveRoomMessage.dart';
import 'package:owl/share_room/messages/ShareRoomInvitationMessage.dart';
import 'package:owl/share_room/models/AckModel.dart';
import 'package:owl/share_room/models/RoomMembershipNotificationModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';
import 'package:owl/share_room/models/UserModel.dart';
import 'package:owl/share_room/server_messages/AckReadServerMessage.dart';
import 'package:owl/share_room/server_messages/AckServerMessage.dart';
import 'package:owl/share_room/server_messages/InvitedToShareRoomServerMessage.dart';
import 'package:owl/share_room/server_messages/IsTypingServerMessage.dart';
import 'package:owl/share_room/server_messages/JoinedServerMessage.dart';
import 'package:owl/share_room/server_messages/NewPalsServerMessage.dart';
import 'package:owl/share_room/server_messages/NewShareItemServerMessage.dart';
import 'package:owl/share_room/server_messages/PalLeftServerMessage.dart';
import 'package:owl/share_room/server_messages/ShareRoomInvitationServerMessage.dart';
import 'package:owl/share_room/server_messages/SuccessfulShareItemCreationServerMessage.dart';
import 'package:owl/share_room/server_messages/SuccessfulShareRoomCreationServerMessage.dart';
import 'package:owl/share_room/services/IShareRoomStorageService.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class ShareRoomService {
  final IMessageService _messageService;
  final IShareRoomStorageService _shareRoomStorageService;
  final IAccountStorageService _accountStorageService;
  final AccountService _accountService;
  final ContactService _contactService;
  final IImageStorageService _imageStorageService;
  final FileSystemStorageService _fileSystemStorageService;
  final ThumbnailGeneratorService _thumbnailGeneratorService;
  final Uuid _uuid;
  final LoggingService _loggingService;

  final PublishSubject<ShareRoomEvent> _eventSubject =
      PublishSubject<ShareRoomEvent>();
  Stream<ShareRoomEvent> get event$ => _eventSubject.stream;

  ShareRoomService(
    this._messageService,
    this._shareRoomStorageService,
    this._accountStorageService,
    this._accountService,
    this._contactService,
    this._imageStorageService,
    this._fileSystemStorageService,
    this._thumbnailGeneratorService,
    this._uuid,
    this._loggingService,
  ) {
    _messageService.onShareRoomServerMessage = _handleServerMessage;
  }

  Future join() async {
    AccountModel account = await _accountStorageService.loadAccount();

    List<ShareRoomModel> unconfirmedRooms =
        await _shareRoomStorageService.getAllUnconfirmedRooms();

    // @@NOTE: Items from oldest to newest
    List<ShareItemModel> unconfirmedItems =
        await _shareRoomStorageService.getAllUnconfirmedItemsWithReasons(
      [
        ShareItemUnconfirmedReason.InProgress,
        ShareItemUnconfirmedReason.ConnectionError,
        ShareItemUnconfirmedReason.ServerError,
      ],
    );

    List<Future<List<Uint8List>>> loadImagesFutures = [];
    for (var shareItem in unconfirmedItems) {
      if (shareItem.type == ShareItemType.Images ||
          shareItem.type == ShareItemType.TextImages) {
        if (shareItem.isUploadedToFirebase) {
          _updateContent(shareItem);
        } else {
          loadImagesFutures.add(_loadImagesFromFileSystem(shareItem));
        }
      }
    }

    if (loadImagesFutures.isNotEmpty) {
      List<List<Uint8List>> imagesPerItem =
          await Future.wait(loadImagesFutures);

      int i = 0;
      for (var shareItem in unconfirmedItems) {
        if ((shareItem.type == ShareItemType.Images ||
                shareItem.type == ShareItemType.TextImages) &&
            !shareItem.isUploadedToFirebase) {
          shareItem.images = imagesPerItem[i++];
        }
      }
    }

    List<Future> uploadImagesAndUpdateContentFutures = [];
    for (var shareItem in unconfirmedItems) {
      if ((shareItem.type == ShareItemType.Images ||
              shareItem.type == ShareItemType.TextImages) &&
          !shareItem.isUploadedToFirebase) {
        uploadImagesAndUpdateContentFutures.add(
          _uploadImagesAndUpdateContent(shareItem),
        );
      }
    }

    if (uploadImagesAndUpdateContentFutures.isNotEmpty) {
      await Future.wait(uploadImagesAndUpdateContentFutures);
    }

    List<RoomMembershipNotificationModel> unconfirmedRoomOperations =
        await _shareRoomStorageService
            .getAllUnconfirmedRoomMembershipOperations();

    List<ShareItemModel> unconfirmedAcks =
        await _shareRoomStorageService.getAllUnconfirmedAcks();

    // @@NOTE: Retrieves confirmed rooms with latest item's time of creation.
    // If no items in the room (or only unconfirmed items) - latest item's time of creation is set to 0.
    List<ShareRoomModel> shareRoomsWithLatestItem =
        await _shareRoomStorageService.getShareRoomsWithLatestItem(
      confirmedOnly: true,
    );

    var msg = JoinMessage(
      sessionIdentifier: account.sessionIdentifier,
      unconfirmedRooms: unconfirmedRooms,
      unconfirmedItems: unconfirmedItems,
      unconfirmedRoomOperations: unconfirmedRoomOperations,
      unconfirmedAcks: unconfirmedAcks,
      shareRoomsWithLatestItem: shareRoomsWithLatestItem,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);

    if (serverMessage is JoinedServerMessage) {
      // @@??: Do not need to await separately ? await them together ?
      List<List<ShareItemModel>> unsentShareItemsPerRoom =
          await _shareRoomStorageService
              .confirmShareRoomsAndUpdateItems(serverMessage.confirmedRooms);

      await _shareRoomStorageService
          .confirmShareItems(serverMessage.confirmedItems);

      await _shareRoomStorageService
          .confirmRoomMembershipOperations(unconfirmedRoomOperations);

      await _shareRoomStorageService.confirmAcks(unconfirmedAcks);

      await _shareRoomStorageService
          .applyRoomMembershipNotifications(serverMessage.notifications);

      await _shareRoomStorageService.ackShareItems(serverMessage.acks);

      if (unsentShareItemsPerRoom != null) {
        for (List<ShareItemModel> unsentShareItems in unsentShareItemsPerRoom) {
          if (unsentShareItems != null && unsentShareItems.isNotEmpty) {
            _sendUnsentShareItems(unsentShareItems);
          }
        }
      }

      for (var notification in serverMessage.notifications) {
        var msg = AckRoomMembershipOperationMessage(
          sessionIdentifier: account.sessionIdentifier,
          notificationIdentifier: notification.identifier,
        );

        _messageService.sendMessage(msg, responseExpected: false);
      }

      List<ShareItemModel> fullyAckedShareItems;
      for (var ack in serverMessage.acks) {
        if (ack.notReceivedPals.isEmpty && ack.notReadPals.isEmpty) {
          fullyAckedShareItems = fullyAckedShareItems ?? List<ShareItemModel>();
          fullyAckedShareItems.add(
            ShareItemModel(
              roomIdentifier: ack.roomIdentifier,
              timeOfCreation: ack.timeOfCreation,
            ),
          );
        }
      }

      if (fullyAckedShareItems != null) {
        var msg = DeleteAcksMessage(
          sessionIdentifier: account.sessionIdentifier,
          shareItems: fullyAckedShareItems,
        );

        _messageService.sendMessage(msg, responseExpected: false);
      }

      List<Future> createShareRoomFutures = [];
      for (var shareRoom in serverMessage.shareRooms) {
        createShareRoomFutures.add(_createShareRoom(shareRoom));
      }

      await Future.wait(createShareRoomFutures);

      List<Future> downloadImagesAndUpdateShareItemFutures = [];
      for (var shareItem in serverMessage.shareItems) {
        if (shareItem.type == ShareItemType.Images ||
            shareItem.type == ShareItemType.TextImages) {
          downloadImagesAndUpdateShareItemFutures.add(
            _downloadImagesAndUpdateShareItem(shareItem),
          );
        }
      }

      if (downloadImagesAndUpdateShareItemFutures.isNotEmpty) {
        await Future.wait(downloadImagesAndUpdateShareItemFutures);

        List<Future> generateThumbnailsFutures = [];
        for (var shareItem in serverMessage.shareItems) {
          if (shareItem.type == ShareItemType.Images ||
              shareItem.type == ShareItemType.TextImages) {
            generateThumbnailsFutures.add(_generateThumbnails(shareItem));
          }
        }

        await Future.wait(generateThumbnailsFutures);

        List<Future> saveImagesToFileSystemFutures = [];
        for (var shareItem in serverMessage.shareItems) {
          if (shareItem.type == ShareItemType.Images ||
              shareItem.type == ShareItemType.TextImages) {
            saveImagesToFileSystemFutures.add(
              _saveImagesToFileSystem(shareItem),
            );
          }
        }

        await Future.wait(saveImagesToFileSystemFutures);
      }

      await _shareRoomStorageService.createShareItems(serverMessage.shareItems);

      // @@TODO: Better way. Send all together ?
      for (var shareItem in serverMessage.shareItems) {
        _ackReceive(shareItem);
      }

      _loggingService.log('Joined Successfully');
      print('Joined Successfully');
    } else {
      _loggingService.log('Join Error: ${serverMessage.messageCode}');
      print('Join Error: ${serverMessage.messageCode}');
    }
  }

  Future _sendUnsentShareItems(List<ShareItemModel> shareItems) async {
    List<Future<List<Uint8List>>> loadImagesFutures = [];
    for (var shareItem in shareItems) {
      if (shareItem.type == ShareItemType.Images ||
          shareItem.type == ShareItemType.TextImages) {
        loadImagesFutures.add(_loadImagesFromFileSystem(shareItem));
      }
    }

    if (loadImagesFutures.isNotEmpty) {
      List<List<Uint8List>> imagesPerItem =
          await Future.wait(loadImagesFutures);
      int i = 0;
      for (var shareItem in shareItems) {
        if (shareItem.type == ShareItemType.Images ||
            shareItem.type == ShareItemType.TextImages) {
          shareItem.images = imagesPerItem[i++];
        }
      }
    }

    List<Future> createShareItemFutures = [];
    // @@TODO: Better way. Send all at once ?
    for (var shareItem in shareItems) {
      // If item contains images, they are not yet uploaded to the image storage.
      createShareItemFutures.add(_createShareItem(shareItem));
    }

    await Future.wait(createShareItemFutures);
  }

  Future createShareRoom(String roomName, List<int> pals) async {
    AccountModel account = await _accountStorageService.loadAccount();

    pals.add(account.userId);
    _loggingService.log('CreateShareRoom. Pals: $pals');
    print('CreateShareRoom. Pals: $pals');
    pals = pals.toSet().toList(growable: false); // redundant

    String requestIdentifier = _uuid.v4();
    Uint8List tempRoomIdentifier = _uuid.v4buffer(Uint8List(16));

    int otherGuyId;
    if (pals.length == 2) {
      int index = pals.indexOf(account.userId) == 0 ? 1 : 0;
      otherGuyId = pals[index];
    }

    var shareRoom = ShareRoomModel(
      requestIdentifier: requestIdentifier,
      identifier: tempRoomIdentifier,
      name: roomName,
      pals: pals,
      isConfirmed: false,
      otherGuyId: otherGuyId,
    );

    await _shareRoomStorageService.createShareRoom(shareRoom);

    // @@TODO: Return before sending message to display newly created room.

    var msg = CreateShareRoomMessage(
      sessionIdentifier: account.sessionIdentifier,
      roomName: roomName,
      pals: pals,
    );
    msg.requestIdentifier = requestIdentifier;

    ServerMessage serverMessage = await _messageService.sendMessage(msg);

    if (serverMessage is SuccessfulShareRoomCreationServerMessage) {
      _loggingService.log('ShareRoom Created Successfully');
      print('ShareRoom Created Successfully');

      List<ShareItemModel> unsentShareItems =
          await _shareRoomStorageService.confirmShareRoomAndUpdateItems(
        requestIdentifier,
        serverMessage.roomIdentifier,
      );

      if (unsentShareItems != null && unsentShareItems.isNotEmpty) {
        return _sendUnsentShareItems(unsentShareItems);
      }
    } else {
      _loggingService.log(
        'CreateShareRoom Error: ${serverMessage.messageCode}',
      );
      print('CreateShareRoom Error: ${serverMessage.messageCode}');
      // @@TODO: Try again later.
    }
  }

  void _updateContent(ShareItemModel shareItem) {
    // Images     null
    //            [Image [Image ...]]
    //            [ImageUrl [ImageUrl ...]]
    // TextImages Content
    //            [Image [Image ...]]
    //            [ImageUrl [ImageUrl ...]]

    var content = List<int>();
    if (shareItem.type == ShareItemType.TextImages) {
      var byteData = Uint8List(4).buffer.asByteData();
      byteData.setInt32(0, shareItem.content.length);
      content.addAll(byteData.buffer.asUint8List());
      content.addAll(shareItem.content);
    }

    for (String imageUrl in shareItem.imageUrls) {
      List<int> imageUrlBytes = utf8.encode(imageUrl);
      content.add(imageUrlBytes.length);
      content.addAll(imageUrlBytes);
    }

    // Images     L1 ImageUrl [L1 ImageUrl ...]
    // TextImages L4 Content L1 ImageUrl [L1 ImageUrl ...]

    shareItem.content = Uint8List.fromList(content);
  }

  Future _uploadImagesAndUpdateContent(ShareItemModel shareItem) async {
    // Images     null
    //            [Image [Image ...]]
    //            [ImageUrl [ImageUrl ...]]
    // TextImages Content
    //            [Image [Image ...]]
    //            [ImageUrl [ImageUrl ...]]

    List<Future> futures = [];
    for (int i = 0; i < shareItem.images.length; ++i) {
      futures.add(
        _imageStorageService.uploadImage(
          shareItem.imageUrls[i],
          shareItem.images[i],
        ),
      );
    }

    await Future.wait(futures);

    await _shareRoomStorageService.confirmUploadingToFirebase(
      shareItem.requestIdentifier,
    );

    _loggingService.log('Image(s) uploaded successfully');
    print('Image(s) uploaded successfully');

    _updateContent(shareItem);
  }

  Future _saveImagesToFileSystem(ShareItemModel shareItem) async {
    List<Future> futures = [];
    for (int i = 0; i < shareItem.images.length; ++i) {
      futures.add(
        _fileSystemStorageService.saveFile(
          shareItem.imageUrls[i],
          shareItem.images[i],
        ),
      );
      futures.add(
        _fileSystemStorageService.saveFile(
          shareItem.thumbnailFilePaths[i],
          shareItem.thumbnails[i],
        ),
      );
    }

    await Future.wait(futures);
  }

  Future<List<Uint8List>> _loadImagesFromFileSystem(ShareItemModel shareItem) {
    List<Future<Uint8List>> futures = [];
    for (String filePath in shareItem.imageUrls) {
      futures.add(_fileSystemStorageService.loadFile(filePath));
    }

    return Future.wait(futures);
  }

  Future _generateThumbnails(ShareItemModel shareItem) async {
    shareItem.thumbnailFilePaths = [];
    List<Future<Uint8List>> futures = [];
    for (int i = 0; i < shareItem.images.length; ++i) {
      futures.add(_thumbnailGeneratorService.generate(shareItem.images[i]));
      shareItem.thumbnailFilePaths.add('${shareItem.imageUrls[i]}_thumbnail');
    }

    shareItem.thumbnails = await Future.wait(futures);
  }

  Future _createShareItem(ShareItemModel shareItem) async {
    if (shareItem.type == ShareItemType.Images ||
        shareItem.type == ShareItemType.TextImages) {
      await _uploadImagesAndUpdateContent(shareItem);
    }

    // Text       Content
    // Images     L1 ImageUrl [L1 ImageUrl ...]
    // TextImages L4 Content L1 ImageUrl [L1 ImageUrl ...]

    AccountModel account = await _accountStorageService.loadAccount();

    var msg = CreateShareItemMessage(
      sessionIdentifier: account.sessionIdentifier,
      roomIdentifier: shareItem.roomIdentifier,
      itemType: shareItem.type,
      itemContent: shareItem.content,
    );
    msg.requestIdentifier = shareItem.requestIdentifier;

    ServerMessage serverMessage = await _messageService.sendMessage(msg);

    if (serverMessage is SuccessfulShareItemCreationServerMessage) {
      await _shareRoomStorageService.confirmShareItem(
        shareItem.requestIdentifier,
        serverMessage.timeOfCreation,
      );

      List<ShareItemModel> shareItems =
          _shareRoomStorageService.updateShareItemsTimeInCache(
        shareItem.id,
        serverMessage.timeOfCreation,
      );

      _eventSubject.add(NewShareItemEvent(shareItems: shareItems));

      _loggingService.log('ShareItem Created Successfully');
      print('ShareItem Created Successfully');
    } else {
      await _shareRoomStorageService.changeItemsUnconfirmedReason(
        shareItem.requestIdentifier,
        ShareItemUnconfirmedReason.ServerError, // @@TODO: Actual reason
      );

      _loggingService.log(
        'CreateShareItem Error: ${serverMessage.messageCode}',
      );
      print('CreateShareItem Error: ${serverMessage.messageCode}');
    }
  }

  Future createShareItem() async {
    Uint8List roomIdentifier = _currentRoomIdentifier;
    if (roomIdentifier == null) {
      return;
    }

    ShareItemType type;
    Uint8List content;
    List<Uint8List> images;

    if (_attachedText != null && _attachedText.isNotEmpty) {
      content = Uint8List.fromList(utf8.encode(_attachedText));
    }

    for (Uint8List image in _attachedImages) {
      images = images ?? [];
      images.add(image);
    }

    if (content != null) {
      type = images == null ? ShareItemType.Text : ShareItemType.TextImages;
    } else if (images != null) {
      type = ShareItemType.Images;
    } else {
      _loggingService.log('Nothing is attached');
      print('Nothing is attached');
      return;
    }

    // Text       Content
    //            null
    // Images     null
    //            [Image [Image ...]]
    // TextImages Content
    //            [Image [Image ...]]

    _attachedText = null;
    _attachedImages.clear();

    AccountModel account = await _accountStorageService.loadAccount();

    _loggingService.log('CreateShareItem: $type $roomIdentifier');
    print('CreateShareItem: $type $roomIdentifier');

    String requestIdentifier = _uuid.v4();

    var shareItem = ShareItemModel(
      requestIdentifier: requestIdentifier,
      roomIdentifier: roomIdentifier,
      creatorId: account.userId,
      timeOfCreation: DateTime.now().toUtc().millisecondsSinceEpoch,
      type: type,
      content: content,
      images: images,
      status: ShareItemStatus.NotReceived,
    );

    if (type == ShareItemType.Images || type == ShareItemType.TextImages) {
      shareItem.imageUrls = [];
      for (int i = 0; i < shareItem.images.length; ++i) {
        shareItem.imageUrls.add(
          'images/${_accountService.firebaseUser.uid}/${_uuid.v4()}',
        );
      }

      // Images     null
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]
      // TextImages Content
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]

      await _generateThumbnails(shareItem);

      // Images     null
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]
      //            [Thumbnail [Thumbnail ...]]
      //            [ThumbnailFilePath [ThumbnailFilePath ...]]
      // TextImages Content
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]
      //            [Thumbnail [Thumbnail ...]]
      //            [ThumbnailFilePath [ThumbnailFilePath ...]]

      await _saveImagesToFileSystem(shareItem);
    }

    // Text       Content
    //            null
    // Images     null
    //            [ImageUrl [ImageUrl ...]]
    // TextImages Content
    //            [ImageUrl [ImageUrl ...]]

    bool needSend =
        await _shareRoomStorageService.checkRoomAndCreateShareItem(shareItem);

    _loggingService.log('Need send: $needSend');
    print('Need send: $needSend');

    if (!needSend) {
      return;
    }

    List<ShareItemModel> shareItems =
        _shareRoomStorageService.addShareItemToCache(shareItem);

    _eventSubject.add(NewShareItemEvent(shareItems: shareItems));

    return _createShareItem(
      ShareItemModel(
        requestIdentifier: shareItem.requestIdentifier,
        id: shareItem.id,
        roomIdentifier: shareItem.roomIdentifier,
        type: shareItem.type,
        content: shareItem.content,
        images: shareItem.images,
        imageUrls: shareItem.imageUrls,
      ),
    );
  }

  Future<List<ShareRoomModel>> getShareRoomsWithLatestItem() async {
    List<ShareRoomModel> shareRooms = await _shareRoomStorageService
        .getShareRoomsWithLatestItem(confirmedOnly: false);

    await _contactService.loadAndUpdateProfilePicturesFromFileSystem(
      shareRooms
          .where((room) => room.otherGuy != null)
          .map((room) => room.otherGuy)
          .toList(),
    );

    return shareRooms;
  }

  final List<Uint8List> _attachedImages = [];

  Future attachImages(List<Asset> imageAssets) async {
    _attachedImages.clear();
    List<Future<ByteData>> futures = [];
    imageAssets.forEach((image) => futures.add(image.getByteData(quality: 50)));
    List<ByteData> images = await Future.wait(futures);
    images.forEach((image) => _attachedImages.add(image.buffer.asUint8List()));
  }

  String _attachedText;

  void attachText(String text) {
    _attachedText = text;
  }

  Future inviteToShareRoom(Uint8List roomIdentifier, List<int> pals) async {
    AccountModel account = await _accountStorageService.loadAccount();
    if (account.sessionIdentifier != null) {
      ShareRoomModel shareRoom =
          await _shareRoomStorageService.getShareRoom(roomIdentifier);
      if (shareRoom != null && shareRoom.isConfirmed) {
        // @@TODO: Check pal count. Check self-invitation. Check already invited pals.

        String requestIdentifier = _uuid.v4();

        await _shareRoomStorageService.createRoomMembershipNotification(
          requestIdentifier,
          roomIdentifier,
          pals: pals,
        );

        var msg = ShareRoomInvitationMessage(
          sessionIdentifier: account.sessionIdentifier,
          roomIdentifier: roomIdentifier,
          pals: pals,
        );
        msg.requestIdentifier = requestIdentifier;

        ServerMessage serverMessage = await _messageService.sendMessage(msg);

        if (serverMessage.messageCode == MessageCode.SuccessfulInvitation) {
          await _shareRoomStorageService.confirmRoomMembershipOperation(
            requestIdentifier,
            roomIdentifier,
            pals: pals,
          );
        } else {
          print('InviteToShareRoom Error: ${serverMessage.messageCode}');
        }
      } else {
        print('InviteToShareRoom Error: Non-existent or unconfirmed room');
        // @@TODO: Try again later ?
      }
    } else {
      print('InviteToShareRoom Error: No SessionIdentifier');
    }
  }

  Future leaveRoom(Uint8List roomIdentifier) async {
    AccountModel account = await _accountStorageService.loadAccount();
    if (account.sessionIdentifier != null) {
      ShareRoomModel shareRoom =
          await _shareRoomStorageService.getShareRoom(roomIdentifier);
      if (shareRoom != null && shareRoom.isConfirmed) {
        String requestIdentifier = _uuid.v4();

        await _shareRoomStorageService.createRoomMembershipNotification(
          requestIdentifier,
          roomIdentifier,
        );

        var msg = LeaveRoomMessage(
          sessionIdentifier: account.sessionIdentifier,
          roomIdentifier: roomIdentifier,
        );
        msg.requestIdentifier = requestIdentifier;

        ServerMessage serverMessage = await _messageService.sendMessage(msg);

        if (serverMessage.messageCode == MessageCode.SuccessfulLeaving) {
          await _shareRoomStorageService.confirmRoomMembershipOperation(
            requestIdentifier,
            roomIdentifier,
          );
        } else {
          print('LeaveRoom Error: ${serverMessage.messageCode}');
        }
      } else {
        print('LeaveRoom Error: Non-existent or unconfirmed room');
      }
    } else {
      print('LeaveRoom Error: No SessionIdentifier');
    }
  }

  Uint8List _currentRoomIdentifier;
  Uint8List get currentRoomIdentifier => _currentRoomIdentifier;

  Future notifyTyping() async {
    AccountModel account = await _accountStorageService.loadAccount();
    if (_currentRoomIdentifier != null) {
      var msg = IsTypingMessage(
        sessionIdentifier: account.sessionIdentifier,
        roomIdentifier: _currentRoomIdentifier,
      );

      _messageService.sendMessage(msg, responseExpected: false);
    }
  }

  Future<List<ShareItemModel>> initializeRoom(Uint8List roomIdentifier) async {
    _currentRoomIdentifier = roomIdentifier;

    List<ShareItemModel> shareItems =
        await _shareRoomStorageService.getShareItemsFromRoom(
      roomIdentifier,
      initial: true,
    );

    // @@NOTE:
    // There is a small chance that some share item is duplicated.
    // New share item arrives and createShareItem is called. After that initialize room
    // event is fired and execution proceedes to the getShareItemsFromRoom, where
    // it blocks waiting for lock to be released. createShareItem executes,
    // following isCurrentRoom check yields true and item is added to the cache (currently empty).
    // getShareItemsFromRoom retrieves items, including newly arrived one, and adds them
    // to the cache, which already holds newly arrived item, so it will get duplicated.

    // We can check if cache already contains an item before adding it, but in the absolute
    // majority of cases it will be unnecessary work. It is purely visual hiccup, item is not
    // actually doubled in the db, and duplicate will be gone with next opening of the room.

    // @@TODO: Remove possible duplicates.

    _ackRead(
      shareItems.where(
        (shareItem) =>
            shareItem.ackedStatus != null &&
            shareItem.ackedStatus != ShareItemAckedStatus.AckedRead,
      ),
    );

    return shareItems;
  }

  void closeRoom() {
    _currentRoomIdentifier = null;
    _shareRoomStorageService.resetShareItemsCache();
  }

  void _handleServerMessage(ServerMessage serverMessage) async {
    // @@TODO: Wait till Joined is processed ? Buffer ?
    Future future;
    if (serverMessage is ShareRoomInvitationServerMessage) {
      future = _handleShareRoomInvitationServerMessage(serverMessage);
    } else if (serverMessage is NewShareItemServerMessage) {
      future = _handleNewShareItemServerMessage(serverMessage);
    } else if (serverMessage is NewPalsServerMessage) {
      future = _handleNewPalsServerMessage(serverMessage);
    } else if (serverMessage is InvitedToShareRoomServerMessage) {
      future = _handleInvitedToShareRoomServerMessage(serverMessage);
    } else if (serverMessage is PalLeftServerMessage) {
      future = _handlePalLeftServerMessage(serverMessage);
    } else if (serverMessage is AckServerMessage) {
      future = _handleAckServerMessage(serverMessage);
    } else if (serverMessage is AckReadServerMessage) {
      future = _handleAckReadServerMessage(serverMessage);
    } else if (serverMessage is IsTypingServerMessage) {
      future = _handleIsTypingServerMessage(serverMessage);
    }

    _logError(future);
  }

  void _logError(Future future) async {
    try {
      await future;
    } catch (e, s) {
      _loggingService.log('$e\n$s');
    }
  }

  Future _createShareRoom(ShareRoomModel shareRoom) async {
    await _contactService.getUnseenUsers(shareRoom.pals);

    AccountModel account = await _accountStorageService.loadAccount();
    if (shareRoom.pals.length == 2) {
      int index = shareRoom.pals.indexOf(account.userId) == 0
          ? 1
          : 0; // @@TODO?: Handle -1
      shareRoom.otherGuyId = shareRoom.pals[index];
    }

    await _shareRoomStorageService.createShareRoom(shareRoom);
  }

  Future _handleShareRoomInvitationServerMessage(
    ShareRoomInvitationServerMessage serverMessage,
  ) async {
    // @@TODO: What if items started arriving before invitation was received ?
    var shareRoom = ShareRoomModel(
      identifier: serverMessage.roomIdentifier,
      name: serverMessage.roomName, // for group chats
      pals: serverMessage.pals,
      isConfirmed: true,
    );

    await _createShareRoom(shareRoom);

    if (_currentRoomIdentifier == null) {
      _eventSubject.add(ShareRoomInvitationEvent());
    }
  }

  Future _downloadImagesAndUpdateShareItem(ShareItemModel shareItem) async {
    // Images     L1 ImageUrl [L1 ImageUrl ...]
    // TextImages L4 Content L1 ImageUrl [L1 ImageUrl ...]

    Uint8List content;
    List<String> imageUrls = [];
    int i = 0;
    if (shareItem.type == ShareItemType.TextImages) {
      int offset = shareItem.content.offsetInBytes;
      int textLength = shareItem.content.buffer.asByteData().getInt32(offset);

      content = Uint8List.view(
        shareItem.content.buffer,
        offset + 4,
        textLength,
      );

      i = 4 + textLength;
    }

    while (i < shareItem.content.length) {
      int imageUrlLength = shareItem.content[i++];
      String imageUrl =
          utf8.decoder.convert(shareItem.content, i, i += imageUrlLength);
      imageUrls.add(imageUrl);
    }

    List<Future<Uint8List>> futures = [];
    for (String imageUrl in imageUrls) {
      futures.add(_imageStorageService.downloadImage(imageUrl));
    }

    shareItem.images = await Future.wait(futures);
    shareItem.imageUrls = imageUrls;
    shareItem.content = content;

    // Images     null
    //            [Image [Image ...]]
    //            [ImageUrl [ImageUrl ...]]
    // TextImages Content
    //            [Image [Image ...]]
    //            [ImageUrl [ImageUrl ...]]
  }

  Future _handleNewShareItemServerMessage(
    NewShareItemServerMessage serverMessage,
  ) async {
    // Text       Content
    // Images     L1 ImageUrl [L1 ImageUrl ...]
    // TextImages L4 Content L1 ImageUrl [L1 ImageUrl ...]

    UserModel creator = await _contactService.getUser(serverMessage.creatorId);

    var shareItem = ShareItemModel(
      roomIdentifier: serverMessage.roomIdentifier,
      creatorId: serverMessage.creatorId,
      timeOfCreation: serverMessage.timeOfCreation,
      type: serverMessage.type,
      content: serverMessage.content,
      creator: creator,
    );

    if (shareItem.type == ShareItemType.Images ||
        shareItem.type == ShareItemType.TextImages) {
      await _downloadImagesAndUpdateShareItem(shareItem);

      // Images     null
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]
      // TextImages Content
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]

      await _generateThumbnails(shareItem);

      // Images     null
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]
      //            [Thumbnail [Thumbnail ...]]
      //            [ThumbnailFilePath [ThumbnailFilePath ...]]
      // TextImages Content
      //            [Image [Image ...]]
      //            [ImageUrl [ImageUrl ...]]
      //            [Thumbnail [Thumbnail ...]]
      //            [ThumbnailFilePath [ThumbnailFilePath ...]]

      await _saveImagesToFileSystem(shareItem);
    }

    // Text       Content
    //            null
    // Images     null
    //            [ImageUrl [ImageUrl ...]]
    // TextImages Content
    //            [ImageUrl [ImageUrl ...]]

    await _shareRoomStorageService.createShareItem(shareItem);

    _loggingService.log('New ShareItem received ${shareItem.type}');
    print('New ShareItem received ${shareItem.type}');

    if (isCurrentRoom(shareItem.roomIdentifier)) {
      List<ShareItemModel> shareItems =
          _shareRoomStorageService.addShareItemToCache(shareItem);

      _eventSubject.add(NewShareItemEvent(shareItems: shareItems));

      return _ackReceiveRead(shareItem);
    } else {
      if (_currentRoomIdentifier == null) {
        _eventSubject.add(ShareRoomInvitationEvent());
      }

      return _ackReceive(shareItem);
    }
  }

  Future _ackReceive(ShareItemModel shareItem) async {
    AccountModel account = await _accountStorageService.loadAccount();

    var msg = AckReceiveMessage(
      sessionIdentifier: account.sessionIdentifier,
      roomIdentifier: shareItem.roomIdentifier,
      timeOfCreation: shareItem.timeOfCreation,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);

    if (serverMessage.messageCode == MessageCode.AckedReceive) {
      await _shareRoomStorageService.changeItemsAckedStatus(
        shareItem.roomIdentifier,
        shareItem.timeOfCreation,
        ShareItemAckedStatus.AckedReceive,
      );
      _loggingService.log('Acked Receive successfully');
      print('Acked Receive successfully');
    } else {
      _loggingService.log('AckReceive Error: ${serverMessage.messageCode}');
      print('AckReceive Error: ${serverMessage.messageCode}');
    }
  }

  Future _ackReceiveRead(ShareItemModel shareItem) async {
    AccountModel account = await _accountStorageService.loadAccount();

    var msg = AckReceiveReadMessage(
      sessionIdentifier: account.sessionIdentifier,
      roomIdentifier: shareItem.roomIdentifier,
      timeOfCreation: shareItem.timeOfCreation,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);

    if (serverMessage.messageCode == MessageCode.AckedReceiveRead) {
      await _shareRoomStorageService.changeItemsAckedStatus(
        shareItem.roomIdentifier,
        shareItem.timeOfCreation,
        ShareItemAckedStatus.AckedRead,
      );
      _loggingService.log('Acked ReceiveRead successfully');
      print('Acked ReceiveRead successfully');
    } else {
      _loggingService.log('AckReceiveRead Error: ${serverMessage.messageCode}');
      print('AckReceiveRead Error: ${serverMessage.messageCode}');
    }
  }

  Future _ackRead(Iterable<ShareItemModel> shareItems) async {
    if (shareItems.isNotEmpty) {
      AccountModel account = await _accountStorageService.loadAccount();

      var msg = AckReadMessage(
        sessionIdentifier: account.sessionIdentifier,
        shareItems: shareItems,
      );

      ServerMessage serverMessage = await _messageService.sendMessage(msg);
      if (serverMessage.messageCode == MessageCode.AckedRead) {
        _loggingService.log('Acked Read successfully');
        print('Acked Read successfully');

        await _shareRoomStorageService.changeItemsAckedStatuses(shareItems);
      } else {
        _loggingService.log('AckRead Error: ${serverMessage.messageCode}');
        print('AckRead Error: ${serverMessage.messageCode}');
      }
    }
  }

  bool isCurrentRoom(Uint8List roomIdentifier) =>
      _arrayEquals(roomIdentifier, _currentRoomIdentifier);

  bool _arrayEquals(Uint8List a, Uint8List b) {
    if (a == null || b == null) {
      return false;
    }

    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; ++i) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  Future _handleNewPalsServerMessage(NewPalsServerMessage serverMessage) async {
    var notification = RoomMembershipNotificationModel(
      identifier: serverMessage.notificationIdentifier,
      roomIdentifier: serverMessage.roomIdentifier,
      operationType: RoomMembershipOperationType.Add,
      pals: serverMessage.pals,
    );

    await _shareRoomStorageService
        .applyRoomMembershipNotification(notification);

    AccountModel account = await _accountStorageService.loadAccount();

    var msg = AckRoomMembershipOperationMessage(
      sessionIdentifier: account.sessionIdentifier,
      notificationIdentifier: notification.identifier,
    );

    _messageService.sendMessage(msg, responseExpected: false);
  }

  Future _handleInvitedToShareRoomServerMessage(
    InvitedToShareRoomServerMessage serverMessage,
  ) async {
    var shareRoom = ShareRoomModel(
      identifier: serverMessage.roomIdentifier,
      name: serverMessage.roomName,
      isConfirmed: true,
      pals: serverMessage.pals,
    );

    await _createShareRoom(shareRoom);

    if (_currentRoomIdentifier == null) {
      _eventSubject.add(ShareRoomInvitationEvent());
    }
  }

  Future _handlePalLeftServerMessage(PalLeftServerMessage serverMessage) async {
    var notification = RoomMembershipNotificationModel(
      identifier: serverMessage.notificationIdentifier,
      roomIdentifier: serverMessage.roomIdentifier,
      operationType: RoomMembershipOperationType.Remove,
      pals: [serverMessage.palId],
    );

    await _shareRoomStorageService
        .applyRoomMembershipNotification(notification);

    AccountModel account = await _accountStorageService.loadAccount();

    var msg = AckRoomMembershipOperationMessage(
      sessionIdentifier: account.sessionIdentifier,
      notificationIdentifier: notification.identifier,
    );

    _messageService.sendMessage(msg, responseExpected: false);
  }

  Future _handleAckServerMessage(AckServerMessage serverMessage) async {
    var ack = AckModel(
      messageCode: serverMessage.messageCode,
      palId: serverMessage.userId,
      roomIdentifier: serverMessage.roomIdentifier,
      timeOfCreation: serverMessage.timeOfCreation,
    );

    ShareItemStatus status = await _shareRoomStorageService.ackShareItem(ack);

    _loggingService.log('Received Ack: ${ack.messageCode}');
    print('Received Ack: ${ack.messageCode}');

    if (isCurrentRoom(ack.roomIdentifier)) {
      List<ShareItemModel> shareItems =
          _shareRoomStorageService.updateShareItemsStatusInCache(ack, status);

      _eventSubject.add(NewShareItemEvent(shareItems: shareItems));
    }
  }

  Future _handleAckReadServerMessage(AckReadServerMessage serverMessage) async {
    List<ShareItemStatus> statuses =
        await _shareRoomStorageService.ackReadShareItems(serverMessage.acks);

    _loggingService.log('Received AckRead');
    print('Received AckRead');

    if (isCurrentRoom(serverMessage.acks.first.roomIdentifier)) {
      List<ShareItemModel> shareItems = _shareRoomStorageService
          .updateShareItemsStatusesInCache(serverMessage.acks, statuses);

      _eventSubject.add(NewShareItemEvent(shareItems: shareItems));
    }
  }

  Future _handleIsTypingServerMessage(
    IsTypingServerMessage serverMessage,
  ) async {
    UserModel user = await _contactService.getUser(serverMessage.userId) ??
        UserModel(id: serverMessage.userId);

    _eventSubject.add(
      IsTypingEvent(
        user: user,
        roomIdentifier: serverMessage.roomIdentifier,
      ),
    );
  }
}
