import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class IsTypingServerMessage extends ServerMessage {
  final Uint8List roomIdentifier;
  final int userId;

  IsTypingServerMessage({this.roomIdentifier, this.userId})
      : super(
          messageCode: MessageCode.IsTyping,
          isResponseToRequest: false,
        );
}
