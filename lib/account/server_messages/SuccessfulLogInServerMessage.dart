import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class SuccessfulLogInServerMessage extends ServerMessage {
  final Uint8List sessionIdentifier;
  final int userId;

  SuccessfulLogInServerMessage({
    String requestIdentifier,
    this.sessionIdentifier,
    this.userId,
  }) : super(
          messageCode: MessageCode.SuccessfulLogIn,
          isResponseToRequest: true,
          requestIdentifier: requestIdentifier,
        );
}
