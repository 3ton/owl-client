import 'dart:typed_data';

import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/UserModel.dart';

class ShareRoomModel {
  final String requestIdentifier;
  final Uint8List identifier;
  final String name;
  final bool isConfirmed;
  final List<int> pals;
  final int unreadCount;
  int otherGuyId;
  final UserModel otherGuy;
  final ShareItemModel latestItem;
  UserModel currentlyTypingGuy;

  ShareRoomModel({
    this.requestIdentifier,
    this.identifier,
    this.name,
    this.isConfirmed,
    this.pals,
    this.unreadCount,
    this.otherGuyId,
    this.otherGuy,
    this.latestItem,
  });
}