import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class AckReceiveReadMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List roomIdentifier;
  final int timeOfCreation;

  AckReceiveReadMessage({
    this.sessionIdentifier,
    this.roomIdentifier,
    this.timeOfCreation,
  });
}