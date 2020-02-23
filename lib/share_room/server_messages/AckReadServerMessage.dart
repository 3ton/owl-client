import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/share_room/models/AckModel.dart';

class AckReadServerMessage extends ServerMessage {
  final List<AckModel> acks;

  AckReadServerMessage({
    this.acks,
  }) : super(
          messageCode: MessageCode.AckRead,
          isResponseToRequest: false,
        );
}
