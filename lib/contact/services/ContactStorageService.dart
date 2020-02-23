import 'dart:typed_data';

import 'package:owl/contact/services/IContactStorageService.dart';
import 'package:owl/general/services/IStorageService.dart';
import 'package:owl/share_room/models/UserModel.dart';

class ContactStorageService implements IContactStorageService {
  final IStorageService _storageService;

  ContactStorageService(this._storageService);

  @override
  Future addMyUser(
    int userId,
    Uint8List username,
    Uint8List firebaseUserIdentifier,
  ) async {
    return await _storageService.addMyUser(
      userId,
      username,
      firebaseUserIdentifier,
    );
  }

  @override
  Future addUsers(List<UserModel> users) async {
    return await _storageService.addUsers(users);
  }

  @override
  Future<List<int>> checkUnseenUsers(List<int> users) async {
    return await _storageService.checkUnseenUsers(users);
  }

  @override
  Future<UserModel> getUser(int userId) async {
    return await _storageService.getUser(userId);
  }

  @override
  Future<UserModel> getMyUser() async {
    return await _storageService.getMyUser();
  }

  @override
  void updateMyUsersProfilePictureInCache(Uint8List profilePicture) {
    return _storageService.updateMyUsersProfilePictureInCache(profilePicture);
  }

  @override
  Future<List<UserModel>> getMyContacts() async {
    return await _storageService.getMyContacts();
  }

  @override
  Future addContact(int userId) async {
    return await _storageService.addContact(userId);
  }

  @override
  Future addContactToFavorites(int userId) async {
    return await _storageService.addContactToFavorites(userId);
  }

  @override
  Future<List<UserModel>> getFavoriteContacts() async {
    return await _storageService.getFavoriteContacts();
  }
}
