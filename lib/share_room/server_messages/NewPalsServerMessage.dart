import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class NewPalsServerMessage extends ServerMessage {
  final Uint8List notificationIdentifier;
  final Uint8List roomIdentifier;
  final List<int> pals;

  NewPalsServerMessage({
    this.notificationIdentifier,
    this.roomIdentifier,
    this.pals,
  }) : super(
          messageCode: MessageCode.NewPals,
          isResponseToRequest: false,
        );
}
