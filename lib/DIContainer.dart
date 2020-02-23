import 'dart:math';

import 'package:kiwi/kiwi.dart';
import 'package:owl/account/managers/AccountManager.dart';
import 'package:owl/account/services/AccountService.dart';
import 'package:owl/account/services/AccountStorageService.dart';
import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/call/managers/CallManager.dart';
import 'package:owl/call/services/ICallService.dart';
import 'package:owl/call/services/WebRtcCallService.dart';
import 'package:owl/contact/managers/ContactManager.dart';
import 'package:owl/contact/services/ContactService.dart';
import 'package:owl/contact/services/ContactStorageService.dart';
import 'package:owl/contact/services/IContactStorageService.dart';
import 'package:owl/general/services/BinaryMessageConverterService.dart';
import 'package:owl/general/services/CacheService.dart';
import 'package:owl/general/services/FileSystemStorageService.dart';
import 'package:owl/general/services/FirebaseStorageService.dart';
import 'package:owl/general/services/IImageStorageService.dart';
import 'package:owl/general/services/IMessageConverterService.dart';
import 'package:owl/general/services/IMessageService.dart';
import 'package:owl/general/services/IStorageService.dart';
import 'package:owl/general/services/MessageService.dart';
import 'package:owl/general/services/StorageService.dart';
import 'package:owl/general/services/ThumbnailGeneratorService.dart';
import 'package:owl/logging/managers/LoggingManager.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/navigator/Router.dart';
import 'package:owl/share_room/managers/ShareRoomManager.dart';
import 'package:owl/share_room/services/IShareRoomStorageService.dart';
import 'package:owl/share_room/services/ShareRoomService.dart';
import 'package:owl/share_room/services/ShareRoomStorageService.dart';
import 'package:uuid/uuid.dart';

part 'DIContainer.g.dart';

abstract class DIContainer {
  static Container container;

  static final resolve = container.resolve;

  static void setup() {
    container = Container();
    _$DIContainer()._configure();
  }

  void _configure() {
    _configureGeneral();
    _configureAccount();
    _configureShareRoom();
    _configureContact();
    _configureCall();
    _configureLogging();
    _configureInstances();
  }

  @Register.singleton(Router)
  @Register.singleton(IStorageService, from: StorageService)
  @Register.singleton(CacheService)
  @Register.singleton(IMessageConverterService, from: BinaryMessageConverterService)
  @Register.singleton(IMessageService, from: MessageService)
  @Register.singleton(IImageStorageService, from: FirebaseStorageService)
  @Register.singleton(FileSystemStorageService)
  @Register.singleton(ThumbnailGeneratorService)
  void _configureGeneral();

  @Register.singleton(AccountService)
  @Register.singleton(IAccountStorageService, from: AccountStorageService)
  @Register.singleton(AccountManager)
  void _configureAccount();

  @Register.singleton(ShareRoomManager)
  @Register.singleton(ShareRoomService)
  @Register.singleton(IShareRoomStorageService, from: ShareRoomStorageService)
  void _configureShareRoom();

  @Register.singleton(ContactManager)
  @Register.singleton(ContactService)
  @Register.singleton(IContactStorageService, from: ContactStorageService)
  void _configureContact();

  @Register.singleton(CallManager)
  @Register.singleton(ICallService, from: WebRtcCallService)
  void _configureCall();

  @Register.singleton(LoggingManager)
  @Register.singleton(LoggingService)
  void _configureLogging();

  _configureInstances() {
    container.registerInstance(Uuid());
    container.registerInstance(Random());
  }
}