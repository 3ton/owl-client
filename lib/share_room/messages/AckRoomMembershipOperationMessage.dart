import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class AckRoomMembershipOperationMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List notificationIdentifier;

  AckRoomMembershipOperationMessage({
    this.sessionIdentifier,
    this.notificationIdentifier,
  });
}
