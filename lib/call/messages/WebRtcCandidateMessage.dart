import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class WebRtcCandidateMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List webRtcSessionIdentifier;
  final int sdpMlineIndex;
  final String sdpMid;
  final String candidate;

  WebRtcCandidateMessage({
    this.sessionIdentifier,
    this.webRtcSessionIdentifier,
    this.sdpMlineIndex,
    this.sdpMid,
    this.candidate,
  });
}
