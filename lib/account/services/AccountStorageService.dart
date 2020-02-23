import 'dart:typed_data';

import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/general/services/IStorageService.dart';

class AccountStorageService implements IAccountStorageService {
  final IStorageService _storageService;

  AccountStorageService(this._storageService);

  @override
  Future<AccountModel> loadAccount() async {
    return await _storageService.loadAccount();
  }

  @override
  Future createAccount(String email, String username, String password, Uint8List userIdentifier) async {
    return await _storageService.createAccount(email, username, password, userIdentifier);
  }

  @override
  Future confirmAccount(Uint8List sessionIdentifier, int userId) async {
    return await _storageService.confirmAccount(sessionIdentifier, userId);
  }
}