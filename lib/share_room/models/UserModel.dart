import 'dart:typed_data';

class UserModel {
  final int id;
  final Uint8List username;
  final Uint8List firebaseUserIdentifier;
  final bool isFavorite;
  Uint8List profilePicture;

  UserModel({
    this.id,
    this.username,
    this.firebaseUserIdentifier,
    this.isFavorite,
    this.profilePicture,
  });
}
