import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class WebRtcAnswerServerMessage extends ServerMessage {
  final Uint8List webRtcSessionIdentifier;
  final String sdp;
  final String type;

  WebRtcAnswerServerMessage({
    this.webRtcSessionIdentifier,
    this.sdp,
    this.type,
  }) : super(
          messageCode: MessageCode.WebRtcAnswer,
          isResponseToRequest: false,
        );
}
