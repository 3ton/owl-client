import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class LeaveRoomMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List roomIdentifier;

  LeaveRoomMessage({this.sessionIdentifier, this.roomIdentifier});
}
