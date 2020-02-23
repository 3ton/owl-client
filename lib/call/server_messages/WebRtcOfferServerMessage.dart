import 'dart:typed_data';

import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';

class WebRtcOfferServerMessage extends ServerMessage {
  final Uint8List webRtcSessionIdentifier;
  final MediaType media;
  final String sdp;
  final String type;

  WebRtcOfferServerMessage({
    this.webRtcSessionIdentifier,
    this.media,
    this.sdp,
    this.type,
  }) : super(
          messageCode: MessageCode.WebRtcOffer,
          isResponseToRequest: false,
        );
}
