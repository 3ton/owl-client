import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class CreateShareRoomMessage extends Message {
  final Uint8List sessionIdentifier;
  final String roomName;
  final List<int> pals;

  CreateShareRoomMessage({this.sessionIdentifier, this.roomName, this.pals});
}
