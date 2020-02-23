import 'dart:convert';
import 'dart:typed_data';

import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/contact/messages/SearchUsersMessage.dart';
import 'package:owl/contact/services/IContactStorageService.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/general/services/FileSystemStorageService.dart';
import 'package:owl/general/services/IImageStorageService.dart';
import 'package:owl/general/services/IMessageService.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/share_room/messages/GetUsersMessage.dart';
import 'package:owl/share_room/models/UserModel.dart';
import 'package:owl/share_room/server_messages/UsersServerMessage.dart';

class ContactService {
  final IAccountStorageService _accountStorageService;
  final IContactStorageService _contactStorageService;
  final IMessageService _messageService;
  final IImageStorageService _imageStorageService;
  final FileSystemStorageService _fileSystemStorageService;
  final LoggingService _loggingService;

  ContactService(
    this._accountStorageService,
    this._contactStorageService,
    this._messageService,
    this._imageStorageService,
    this._fileSystemStorageService,
    this._loggingService,
  );

  Future<UserModel> getUser(int userId) {
    return _contactStorageService.getUser(userId);
  }

  Future<List<UserModel>> getMyContacts() async {
    List<UserModel> users = await _contactStorageService.getMyContacts();
    await loadAndUpdateProfilePicturesFromFileSystem(users);

    return users;
  }

  Future<List<UserModel>> getFavoriteContacts() async {
    List<UserModel> users = await _contactStorageService.getFavoriteContacts();
    await loadAndUpdateProfilePicturesFromFileSystem(users);

    return users;
  }

  Future<List<UserModel>> searchUsers(String emailUsernameId) async {
    AccountModel account = await _accountStorageService.loadAccount();

    var msg = SearchUsersMessage(
      sessionIdentifier: account.sessionIdentifier,
      emailUsernameId: emailUsernameId,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);
    if (serverMessage is UsersServerMessage) {
      if (serverMessage.users.isNotEmpty) {
        List<int> unseenUserIds = await _contactStorageService.checkUnseenUsers(
          serverMessage.users.map((user) => user.id).toList(),
        );

        List<UserModel> seenUsers;
        if (unseenUserIds.isNotEmpty) {
          List<UserModel> unseenUsers = serverMessage.users
              .where((user) => unseenUserIds.contains(user.id))
              .toList();

          await _downloadAndUpdateProfilePictures(unseenUsers);
          await _saveProfilePicturesToFileSystem(unseenUsers);
          await _contactStorageService.addUsers(unseenUsers);

          seenUsers = serverMessage.users
              .where((user) => !unseenUserIds.contains(user.id))
              .toList();
        } else {
          seenUsers = serverMessage.users;
        }

        await loadAndUpdateProfilePicturesFromFileSystem(seenUsers);
      } else {
        _loggingService.log('No Users Found');
        print('No Users Found');
      }

      return serverMessage.users;
    }

    _loggingService.log('SearchUsers Error: ${serverMessage.messageCode}');
    print('SearchUsers Error: ${serverMessage.messageCode}');

    return null;
  }

  Future getUnseenUsers(List<int> users) async {
    AccountModel account = await _accountStorageService.loadAccount();

    List<int> unseenUsers =
        await _contactStorageService.checkUnseenUsers(users);

    if (unseenUsers.isNotEmpty) {
      var msg = GetUsersMessage(
        sessionIdentifier: account.sessionIdentifier,
        users: unseenUsers,
      );

      ServerMessage serverMessage = await _messageService.sendMessage(msg);
      if (serverMessage is UsersServerMessage) {
        if (serverMessage.users.isNotEmpty) {
          await _downloadAndUpdateProfilePictures(serverMessage.users);
          await _saveProfilePicturesToFileSystem(serverMessage.users);
          await _contactStorageService.addUsers(serverMessage.users);
        }
      } else {
        _loggingService
            .log('GetUnseenUsers Error: ${serverMessage.messageCode}');
        print('GetUnseenUsers Error: ${serverMessage.messageCode}');

        // @@TODO: Schedule for later resend ?
      }
    }
  }

  Future _downloadAndUpdateProfilePictures(List<UserModel> users) async {
    if (users.isEmpty) {
      return;
    }

    List<Future<Uint8List>> futures = [];
    for (var user in users) {
      futures.add(
        _imageStorageService.downloadImage(
          'images/${utf8.decode(user.firebaseUserIdentifier)}/profile_picture',
        ),
      );
    }

    List<Uint8List> profilePictures = await Future.wait(futures);

    for (int i = 0; i < users.length; ++i) {
      users[i].profilePicture = profilePictures[i];
    }
  }

  Future _saveProfilePicturesToFileSystem(List<UserModel> users) async {
    if (users.isEmpty) {
      return;
    }

    List<Future> futures = [];
    for (var user in users) {
      if (user.profilePicture != null) {
        futures.add(
          _fileSystemStorageService.saveFile(
            'images/${utf8.decode(user.firebaseUserIdentifier)}/profile_picture',
            user.profilePicture,
          ),
        );
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future loadAndUpdateProfilePicturesFromFileSystem(
    List<UserModel> users,
  ) async {
    if (users.isEmpty) {
      return;
    }

    List<Future<Uint8List>> futures = [];
    for (var user in users) {
      futures.add(
        _fileSystemStorageService.loadFile(
          'images/${utf8.decode(user.firebaseUserIdentifier)}/profile_picture',
        ),
      );
    }

    List<Uint8List> profilePictures = await Future.wait(futures);
    for (int i = 0; i < users.length; ++i) {
      users[i].profilePicture = profilePictures[i++];
    }
  }
}
