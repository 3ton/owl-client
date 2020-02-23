import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class WebRtcInquireServerMessage extends ServerMessage {
  final int userId;
  final Uint8List webRtcSessionIdentifier;

  WebRtcInquireServerMessage({
    this.userId,
    this.webRtcSessionIdentifier,
  }) : super(
          messageCode: MessageCode.WebRtcInquire,
          isResponseToRequest: false,
        );
}
