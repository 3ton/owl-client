import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';

class AckReadMessage extends Message {
  final Uint8List sessionIdentifier;
  final Iterable<ShareItemModel> shareItems;

  AckReadMessage({
    this.sessionIdentifier,
    this.shareItems,
  });
}
