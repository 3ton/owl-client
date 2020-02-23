import 'package:owl/general/messages/MessageCode.dart';

class ServerMessage {
  final MessageCode messageCode;
  final bool isResponseToRequest;
  final String requestIdentifier;

  ServerMessage({
    this.messageCode,
    this.isResponseToRequest,
    this.requestIdentifier,
  });
}
