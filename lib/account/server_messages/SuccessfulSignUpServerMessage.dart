import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class SuccessfulSignUpServerMessage extends ServerMessage {
  final Uint8List userIdentifier;

  SuccessfulSignUpServerMessage({
    String requestIdentifier,
    this.userIdentifier,
  }) : super(
          messageCode: MessageCode.SuccessfulSignUp,
          isResponseToRequest: true,
          requestIdentifier: requestIdentifier,
        );
}
