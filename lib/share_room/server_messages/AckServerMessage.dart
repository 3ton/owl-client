import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class AckServerMessage extends ServerMessage {
  final int userId;
  final Uint8List roomIdentifier;
  final int timeOfCreation;

  AckServerMessage({
    MessageCode messageCode,
    this.userId,
    this.roomIdentifier,
    this.timeOfCreation,
  }) : super(
          messageCode: messageCode,
          isResponseToRequest: false,
        );
}
