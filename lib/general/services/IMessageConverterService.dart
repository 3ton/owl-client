import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

abstract class IMessageConverterService {
  List<int> encodeMessage(Message msg);
  ServerMessage decodeServerMessage(Uint8List message);
}
