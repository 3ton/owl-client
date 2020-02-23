import 'dart:typed_data';

import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/general/messages/Message.dart';

class WebRtcOfferMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List webRtcsessionIdentifier;
  final MediaType media;
  final String sdp;
  final String type;

  WebRtcOfferMessage({
    this.sessionIdentifier,
    this.webRtcsessionIdentifier,
    this.media,
    this.sdp,
    this.type,
  });
}
