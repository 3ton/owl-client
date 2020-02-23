import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';
import 'package:owl/share_room/models/RoomMembershipNotificationModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';

class JoinMessage extends Message {
  final Uint8List sessionIdentifier;
  final List<ShareRoomModel> unconfirmedRooms;
  final List<ShareItemModel> unconfirmedItems;
  final List<RoomMembershipNotificationModel> unconfirmedRoomOperations;
  final List<ShareItemModel> unconfirmedAcks;
  final List<ShareRoomModel> shareRoomsWithLatestItem;

  JoinMessage({
    this.sessionIdentifier,
    this.unconfirmedRooms,
    this.unconfirmedItems,
    this.unconfirmedRoomOperations,
    this.unconfirmedAcks,
    this.shareRoomsWithLatestItem,
  });
}
