import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';
import 'package:owl/share_room/enums/ShareItemType.dart';

class CreateShareItemMessage extends Message {
  final Uint8List sessionIdentifier;
  final Uint8List roomIdentifier;
  final ShareItemType itemType;
  final Uint8List itemContent;

  CreateShareItemMessage({
    this.sessionIdentifier,
    this.roomIdentifier,
    this.itemType,
    this.itemContent,
  });
}
