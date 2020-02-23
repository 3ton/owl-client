import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class WebRtcServerMessage extends ServerMessage {
  final Uint8List webRtcSessionIdentifier;

  WebRtcServerMessage({
    MessageCode messageCode,
    this.webRtcSessionIdentifier,
  }) : super(
          messageCode: messageCode,
          isResponseToRequest: false,
        );
}
