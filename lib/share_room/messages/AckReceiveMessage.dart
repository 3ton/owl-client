import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class AckReceiveMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List roomIdentifier;
  final int timeOfCreation;

  AckReceiveMessage({
    this.sessionIdentifier,
    this.roomIdentifier,
    this.timeOfCreation,
  });
}
