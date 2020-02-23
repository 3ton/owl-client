import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class WebRtcAnswerMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List webRtcSessionIdentifier;
  final String sdp;
  final String type;

  WebRtcAnswerMessage({
    this.sessionIdentifier,
    this.webRtcSessionIdentifier,
    this.sdp,
    this.type,
  });
}
