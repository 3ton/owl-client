import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:owl/account/messages/ConfirmEmailMessage.dart';
import 'package:owl/account/messages/SignUpMessage.dart';
import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/account/server_messages/SuccessfulLogInServerMessage.dart';
import 'package:owl/account/server_messages/SuccessfulSignUpServerMessage.dart';
import 'package:owl/account/service_results/service_results.dart';
import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/contact/services/IContactStorageService.dart';
import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/general/services/FileSystemStorageService.dart';
import 'package:owl/general/services/IImageStorageService.dart';
import 'package:owl/general/services/IMessageService.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/share_room/messages/AddFirebaseUserMessage.dart';

class AccountService {
  final IMessageService _messageService;
  final IAccountStorageService _accountStorageService;
  final IContactStorageService _contactStorageService;
  final IImageStorageService _imageStorageService;
  final FileSystemStorageService _fileSystemStorageService;
  final LoggingService _loggingService;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseUser _firebaseUser;
  FirebaseUser get firebaseUser => _firebaseUser;

  AccountService(
    this._messageService,
    this._accountStorageService,
    this._contactStorageService,
    this._imageStorageService,
    this._fileSystemStorageService,
    this._loggingService,
  );

  Future<SignUpServiceResult> signUp(
    String email,
    String username,
    String password,
  ) async {
    var msg = SignUpMessage(
      email: email,
      username: username,
      password: password,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);

    if (serverMessage is SuccessfulSignUpServerMessage) {
      await _accountStorageService.createAccount(
        email,
        username,
        password,
        serverMessage.userIdentifier,
      );

      _loggingService.log('Successfully Signed Up');

      return SignUpServiceResult(successMessage: 'Successfully Signed Up');
    }

    // @@TODO: Handle EmailAlreadyInUse and ServerError.

    return SignUpServiceResult(errorMessage: '${serverMessage.messageCode}');
  }

  Future<ConfirmEmailServiceResult> confirmEmail(
    String confirmationCode,
  ) async {
    AccountModel account = await _accountStorageService.loadAccount();

    // @@TODO: Handle no account, already confirmed.

    var msg = ConfirmEmailMessage(
      userIdentifier: account.userIdentifier,
      confirmationCode: confirmationCode,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);

    if (serverMessage is SuccessfulLogInServerMessage) {
      await _accountStorageService.confirmAccount(
        serverMessage.sessionIdentifier,
        serverMessage.userId,
      );

      try {
        AuthResult res = await _firebaseAuth.createUserWithEmailAndPassword(
          email: account.email,
          password: account.password,
        );

        _firebaseUser = res.user;
      } catch (e) {
        return ConfirmEmailServiceResult(
          errorMessage: 'ConfirmEmail -> Firebase Error: $e',
        );
      }

      await _contactStorageService.addMyUser(
        serverMessage.userId,
        Uint8List.fromList(utf8.encode(account.username)),
        Uint8List.fromList(utf8.encode(firebaseUser.uid)),
      );

      var msg2 = AddFirebaseUserMessage(
        sessionIdentifier: serverMessage.sessionIdentifier,
        firebaseUserIdentifier: firebaseUser.uid,
      );

      ServerMessage serverMessage2 = await _messageService.sendMessage(msg2);
      if (serverMessage2.messageCode ==
          MessageCode.SuccessfulFirebaseUserAdding) {
        _loggingService.log('Account confirmed successfully');

        return ConfirmEmailServiceResult(
          successMessage: 'Account confirmed successfully',
        );
      } else {
        return ConfirmEmailServiceResult(
          errorMessage:
              'ConfirmEmail -> Firebase -> AddFirebaseUser Error: ${serverMessage2.messageCode}',
        );
      }
    }

    // @@TODO: Handle UserNotFound, InvalidConfirmationCode, and ServerError.

    return ConfirmEmailServiceResult(
      errorMessage: 'ConfirmEmail Error: ${serverMessage.messageCode}',
    );
  }

  Future<SignInServiceResult> signIn() async {
    AccountModel account = await _accountStorageService.loadAccount();
    
    try {
      AuthResult res = await _firebaseAuth.signInWithEmailAndPassword(
        email: account.email,
        password: account.password,
      );

      _firebaseUser = res.user;

      return SignInServiceResult(successMessage: 'Signed-in successfully');
    } catch (e) {
      _loggingService.log(e.toString());
      print(e.toString());
      
      return SignInServiceResult(errorMessage: e.toString());
    }
  }

  Future<AddProfilePictureServiceResult> addProfilePicture(
    Asset profilePicture,
  ) async {
    try {
      Uint8List profilePictureBytes =
          (await profilePicture.getByteData(quality: 30)).buffer.asUint8List();

      await _fileSystemStorageService.saveFile(
        'images/${_firebaseUser.uid}/profile_picture',
        profilePictureBytes,
      );

      await _imageStorageService.uploadImage(
        'images/${_firebaseUser.uid}/profile_picture',
        profilePictureBytes,
      );

      _contactStorageService
          .updateMyUsersProfilePictureInCache(profilePictureBytes);

      _loggingService.log('Profile picture added successfully');

      return AddProfilePictureServiceResult(
        successMessage: 'Profile picture added successfully',
      );
    } catch (e) {
      return AddProfilePictureServiceResult(errorMessage: e.toString());
    }
  }
}
