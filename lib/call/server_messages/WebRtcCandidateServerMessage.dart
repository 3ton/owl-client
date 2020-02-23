import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class WebRtcCandidateServerMessage extends ServerMessage {
  final Uint8List webRtcSessionIdentifier;
  final int sdpMlineIndex;
  final String sdpMid;
  final String candidate;

  WebRtcCandidateServerMessage({
    this.webRtcSessionIdentifier,
    this.sdpMlineIndex,
    this.sdpMid,
    this.candidate,
  }) : super(
          messageCode: MessageCode.WebRtcCandidate,
          isResponseToRequest: false,
        );
}
