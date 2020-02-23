import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class PalLeftServerMessage extends ServerMessage {
  final Uint8List notificationIdentifier;
  final Uint8List roomIdentifier;
  final int palId;

  PalLeftServerMessage({
    this.notificationIdentifier,
    this.roomIdentifier,
    this.palId,
  }) : super(
          messageCode: MessageCode.PalLeft,
          isResponseToRequest: false,
        );
}
