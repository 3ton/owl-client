import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class IsTypingMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List roomIdentifier;

  IsTypingMessage({this.sessionIdentifier, this.roomIdentifier});
}