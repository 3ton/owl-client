import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class SuccessfulShareItemCreationServerMessage extends ServerMessage {
  final int timeOfCreation;

  SuccessfulShareItemCreationServerMessage({
    String requestIdentifier,
    this.timeOfCreation,
  }) : super(
          messageCode: MessageCode.SuccessfulShareItemCreation,
          isResponseToRequest: true,
          requestIdentifier: requestIdentifier,
        );
}
