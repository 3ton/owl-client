// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DIContainer.dart';

// **************************************************************************
// InjectorGenerator
// **************************************************************************

class _$DIContainer extends DIContainer {
  void _configureGeneral() {
    final Container container = Container();
    container.registerSingleton((c) => Router());
    container.registerSingleton<IStorageService, StorageService>((c) =>
        StorageService(c<FileSystemStorageService>(), c<CacheService>(),
            c<LoggingService>()));
    container.registerSingleton((c) => CacheService());
    container.registerSingleton<IMessageConverterService,
            BinaryMessageConverterService>(
        (c) => BinaryMessageConverterService(c<Uuid>()));
    container.registerSingleton<IMessageService, MessageService>(
        (c) => MessageService(c<IMessageConverterService>(), c<Uuid>()));
    container.registerSingleton<IImageStorageService, FirebaseStorageService>(
        (c) => FirebaseStorageService());
    container.registerSingleton(
        (c) => FileSystemStorageService(c<LoggingService>()));
    container.registerSingleton((c) => ThumbnailGeneratorService());
  }

  void _configureAccount() {
    final Container container = Container();
    container.registerSingleton((c) => AccountService(
        c<IMessageService>(),
        c<IAccountStorageService>(),
        c<IContactStorageService>(),
        c<IImageStorageService>(),
        c<FileSystemStorageService>(),
        c<LoggingService>()));
    container.registerSingleton<IAccountStorageService, AccountStorageService>(
        (c) => AccountStorageService(c<IStorageService>()));
    container.registerSingleton((c) => AccountManager(
        c<AccountService>(),
        c<IAccountStorageService>(),
        c<IContactStorageService>(),
        c<LoggingService>()));
  }

  void _configureShareRoom() {
    final Container container = Container();
    container.registerSingleton((c) => ShareRoomManager(c<ShareRoomService>(),
        c<IShareRoomStorageService>(), c<LoggingService>()));
    container.registerSingleton((c) => ShareRoomService(
        c<IMessageService>(),
        c<IShareRoomStorageService>(),
        c<IAccountStorageService>(),
        c<AccountService>(),
        c<ContactService>(),
        c<IImageStorageService>(),
        c<FileSystemStorageService>(),
        c<ThumbnailGeneratorService>(),
        c<Uuid>(),
        c<LoggingService>()));
    container
        .registerSingleton<IShareRoomStorageService, ShareRoomStorageService>(
            (c) => ShareRoomStorageService(c<IStorageService>()));
  }

  void _configureContact() {
    final Container container = Container();
    container.registerSingleton((c) => ContactManager(
        c<ContactService>(), c<IContactStorageService>(), c<LoggingService>()));
    container.registerSingleton((c) => ContactService(
        c<IAccountStorageService>(),
        c<IContactStorageService>(),
        c<IMessageService>(),
        c<IImageStorageService>(),
        c<FileSystemStorageService>(),
        c<LoggingService>()));
    container.registerSingleton<IContactStorageService, ContactStorageService>(
        (c) => ContactStorageService(c<IStorageService>()));
  }

  void _configureCall() {
    final Container container = Container();
    container.registerSingleton(
        (c) => CallManager(c<ICallService>(), c<LoggingService>()));
    container.registerSingleton<ICallService, WebRtcCallService>((c) =>
        WebRtcCallService(c<IAccountStorageService>(), c<IMessageService>(),
            c<ContactService>(), c<LoggingService>(), c<Uuid>()));
  }

  void _configureLogging() {
    final Container container = Container();
    container.registerSingleton((c) => LoggingManager(c<LoggingService>()));
    container.registerSingleton((c) => LoggingService());
  }
}
