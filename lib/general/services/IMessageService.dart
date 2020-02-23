import 'package:owl/general/messages/Message.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

abstract class IMessageService {
  set onShareRoomServerMessage(void Function(ServerMessage) value);
  set onWebRtcServerMessage(void Function(ServerMessage) value);
  Future<ServerMessage> sendMessage(Message msg, {bool responseExpected = true});
}
