import 'dart:typed_data';

import 'package:owl/share_room/models/UserModel.dart';

abstract class IContactStorageService {
  Future<List<int>> checkUnseenUsers(List<int> users);

  Future addMyUser(
    int userId,
    Uint8List username,
    Uint8List firebaseUserIdentifier,
  );

  Future addUsers(List<UserModel> users);

  Future<UserModel> getUser(int userId);
  
  Future<UserModel> getMyUser();

  void updateMyUsersProfilePictureInCache(Uint8List profilePicture);

  Future<List<UserModel>> getMyContacts();

  Future addContact(int userId);

  Future addContactToFavorites(int userId);

  Future<List<UserModel>> getFavoriteContacts();
}