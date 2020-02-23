import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/contact/services/IContactStorageService.dart';
import 'package:owl/share_room/services/IShareRoomStorageService.dart';

abstract class IStorageService implements
  IShareRoomStorageService,
  IAccountStorageService,
  IContactStorageService {}