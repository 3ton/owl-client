import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';
import 'package:owl/general/messages/MessageCode.dart';

class WebRtcMessage extends Message {
  final MessageCode messageCode;
  final Uint8List sessionIdentifier;
  final Uint8List webRtcSessionIdentifier;

  WebRtcMessage({
    this.messageCode,
    this.sessionIdentifier,
    this.webRtcSessionIdentifier,
  });
}
