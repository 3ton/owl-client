import 'dart:typed_data';

import 'package:owl/share_room/models/UserModel.dart';

class AccountModel {
  final String email;
  final String username;
  final String password;
  final Uint8List userIdentifier;
  final int userId;
  final bool isConfirmed;
  final Uint8List sessionIdentifier;
  UserModel user;

  AccountModel({
    this.email,
    this.username,
    this.password,
    this.userIdentifier,
    this.userId,
    this.isConfirmed,
    this.sessionIdentifier,
    this.user,
  });
}
