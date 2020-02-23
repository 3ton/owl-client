import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class ShareRoomInvitationServerMessage extends ServerMessage {
  final int creatorId;
  final Uint8List roomIdentifier;
  final String roomName;
  final List<int> pals;

  ShareRoomInvitationServerMessage({
    this.creatorId,
    this.roomIdentifier,
    this.roomName,
    this.pals,
  }) : super(
          messageCode: MessageCode.ShareRoomInvitation,
          isResponseToRequest: false,
        );
}
