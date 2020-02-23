import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class SuccessfulShareRoomCreationServerMessage extends ServerMessage {
  final Uint8List roomIdentifier;

  SuccessfulShareRoomCreationServerMessage({
    String requestIdentifier,
    this.roomIdentifier,
  }) : super(
          messageCode: MessageCode.SuccessfulShareRoomCreation,
          isResponseToRequest: true,
          requestIdentifier: requestIdentifier,
        );
}
