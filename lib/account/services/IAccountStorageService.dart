import 'dart:typed_data';

import 'package:owl/account/models/AccountModel.dart';

abstract class IAccountStorageService {
  Future<AccountModel> loadAccount();
  Future createAccount(String email, String username, String password, Uint8List userIdentifier);
  Future confirmAccount(Uint8List sessionIdentifier, int userId);
}