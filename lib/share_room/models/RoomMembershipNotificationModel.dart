import 'dart:typed_data';

import 'package:owl/share_room/enums/RoomMembershipOperationType.dart';

class RoomMembershipNotificationModel {
  final String requestIdentifier;
  final Uint8List identifier;
  final Uint8List roomIdentifier;
  final RoomMembershipOperationType operationType;
  final List<int> pals;

  RoomMembershipNotificationModel({
    this.requestIdentifier,
    this.identifier,
    this.roomIdentifier,
    this.operationType,
    this.pals,
  });
}
