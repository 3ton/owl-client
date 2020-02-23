import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class InvitedToShareRoomServerMessage extends ServerMessage {
  final int inviterId;
  final Uint8List roomIdentifier;
  final String roomName;
  final List<int> pals;

  InvitedToShareRoomServerMessage({
    this.inviterId,
    this.roomIdentifier,
    this.roomName,
    this.pals,
  }) : super(
          messageCode: MessageCode.InvitedToShareRoom,
          isResponseToRequest: false,
        );
}
