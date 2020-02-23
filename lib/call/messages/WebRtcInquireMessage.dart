import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class WebRtcInquireMessage extends Message {
  final Uint8List sessionIdentifier;
  final int userId;
  final Uint8List webRtcSessionIdentifier;

  WebRtcInquireMessage({
    this.sessionIdentifier,
    this.userId,
    this.webRtcSessionIdentifier,
  });
}
