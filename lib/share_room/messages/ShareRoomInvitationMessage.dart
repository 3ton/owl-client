import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class ShareRoomInvitationMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List roomIdentifier;
  final List<int> pals;

  ShareRoomInvitationMessage({
    this.sessionIdentifier,
    this.roomIdentifier,
    this.pals,
  });
}
