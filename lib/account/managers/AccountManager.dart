import 'dart:async';
import 'dart:convert';

import 'package:owl/account/events/events.dart';
import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/account/service_results/service_results.dart';
import 'package:owl/account/services/AccountService.dart';
import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/contact/services/IContactStorageService.dart';
import 'package:owl/general/mixins/WatchCombinedStateMixin.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:rxdart/rxdart.dart';

class AccountManager with WatchCombinedStateMixin {
  final AccountService _accountService;
  final IAccountStorageService _accountStorageService;
  final IContactStorageService _contactStorageService;
  final LoggingService _loggingService;

  final PublishSubject<AccountEvent> _eventSubject =
      PublishSubject<AccountEvent>();
  Sink<AccountEvent> get inEvent => _eventSubject.sink;

  final PublishSubject<AccountModel> _loadAccountSubject =
      PublishSubject<AccountModel>();
  Stream<AccountModel> get loadAccount$ => _loadAccountSubject.stream;

  BehaviorSubject<String> _emailSubject = BehaviorSubject<String>();
  Stream<String> get email$ => _emailSubject.stream;

  BehaviorSubject<String> _usernameSubject = BehaviorSubject<String>();
  Stream<String> get username$ => _usernameSubject.stream;

  BehaviorSubject<String> _passwordSubject = BehaviorSubject<String>();
  Stream<String> get password$ => _passwordSubject.stream;

  Stream<bool> get signUpFormIsValid$ =>
      watchCombinedState([email$, username$, password$]);

  final PublishSubject<String> _signUpSubject = PublishSubject<String>();
  Stream<String> get signUp$ => _signUpSubject.stream;

  BehaviorSubject<String> _confirmationCodeSubject = BehaviorSubject<String>();
  Stream<String> get confirmationCode$ => _confirmationCodeSubject.stream;

  Stream<bool> get confirmEmailFormIsValid$ =>
      watchCombinedState([confirmationCode$]);

  final PublishSubject<String> _confirmEmailSubject = PublishSubject<String>();
  Stream<String> get confirmEmail$ => _confirmEmailSubject.stream;

  final PublishSubject<String> _signInSubject = PublishSubject<String>();
  Stream<String> get signIn$ => _signInSubject.stream;

  AccountManager(
    this._accountService,
    this._accountStorageService,
    this._contactStorageService,
    this._loggingService,
  ) {
    _eventSubject.listen((event) {
      if (event is LoadAccountEvent) {
        _loadAccount();
      } else if (event is ValidateSignUpFormEvent) {
        _validateSignUpForm(event);
      } else if (event is SignUpEvent) {
        _signUp();
      } else if (event is ValidateConfirmEmailFormEvent) {
        _validateConfirmEmailForm(event);
      } else if (event is ConfirmEmailEvent) {
        _confirmEmail();
      } else if (event is AddProfilePictureEvent) {
        _addProfilePicture(event);
      } else if (event is SignInEvent) {
        _signIn();
      }
    });
  }

  void _loadAccount() async {
    AccountModel account = await _accountStorageService.loadAccount();
    if (account != null) {
      account.user = await _contactStorageService.getMyUser();
    }

    _loadAccountSubject.add(account);
  }

  // @@TODO: Move somewhere else
  void _validateSignUpForm(ValidateSignUpFormEvent event) {
    if (event.email != null) {
      var regExp = RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?");
      List<int> emailBytes = utf8.encode(event.email);
      if (emailBytes.length > 255) {
        _emailSubject.addError('Email is too long');
      } else if (!regExp.hasMatch(event.email)) {
        // @@TODO: Regular expression
        _emailSubject.addError('Not a valid email');
      } else {
        _emailSubject.add(event.email);
      }
    } else if (event.username != null) {
      List<int> usernameBytes = utf8.encode(event.username);
      if (usernameBytes.length > 255) {
        _usernameSubject.addError('Username is too long');
      } else if (usernameBytes.length < 6) {
        _usernameSubject.addError('Username is too short');
      } else {
        _usernameSubject.add(event.username);
      }
    } else {
      List<int> passwordBytes = utf8.encode(event.password);
      if (passwordBytes.length > 255) {
        _passwordSubject.addError('Password is too long');
      } else if (passwordBytes.length < 6) {
        _passwordSubject.addError('Password is too short');
      } else {
        _passwordSubject.add(event.password);
      }
    }
  }

  void _signUp() async {
    SignUpServiceResult serviceResult = await _accountService.signUp(
      _emailSubject.value,
      _usernameSubject.value,
      _passwordSubject.value,
    );

    if (serviceResult.errorMessage != null) {
      _signUpSubject.addError(serviceResult.errorMessage);
    } else {
      _signUpSubject.add(serviceResult.successMessage);
    }
  }

  // @@TODO: Move somewhere else
  void _validateConfirmEmailForm(ValidateConfirmEmailFormEvent event) {
    var validCharacters = '0123456789';
    for (int i = 0; i < event.confirmationCode.length; ++i) {
      var c = event.confirmationCode[i];
      if (!validCharacters.contains(c)) {
        _confirmationCodeSubject.addError('Must be all digits');
        return;
      }
    }
    if (event.confirmationCode.length != 6) {
      _confirmationCodeSubject.addError('Must be exactly 6 digits long');
    } else {
      _confirmationCodeSubject.add(event.confirmationCode);
    }
  }

  void _confirmEmail() async {
    ConfirmEmailServiceResult serviceResult =
        await _accountService.confirmEmail(_confirmationCodeSubject.value);

    if (serviceResult.errorMessage != null) {
      _confirmEmailSubject.addError(serviceResult.errorMessage);
    } else {
      _confirmEmailSubject.add(serviceResult.successMessage);
    }
  }

  void _addProfilePicture(AddProfilePictureEvent event) async {
    AddProfilePictureServiceResult serviceResult =
        await _accountService.addProfilePicture(event.profilePicture);

    if (serviceResult.errorMessage != null) {
      print('AddProfilePicture Error: ${serviceResult.errorMessage}');
    } else {
      _loadAccount();
      print(serviceResult.successMessage);
    }
  }

  void _signIn() async {
    SignInServiceResult serviceResult = await _accountService.signIn();
    if (serviceResult.errorMessage != null) {
      _signInSubject.addError(serviceResult.errorMessage);
    } else {
      _signInSubject.add(serviceResult.successMessage);
    }
  }

  void resetSignUpFormSubjects() {
    _emailSubject.close();
    _emailSubject = BehaviorSubject<String>();
    _usernameSubject.close();
    _usernameSubject = BehaviorSubject<String>();
    _passwordSubject.close();
    _passwordSubject = BehaviorSubject<String>();
  }

  void resetConfirmEmailFormSubjects() {
    _confirmationCodeSubject.close();
    _confirmationCodeSubject = BehaviorSubject<String>();
  }
}
