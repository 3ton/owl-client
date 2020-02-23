import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';

class DeleteAcksMessage extends Message {
  final Uint8List sessionIdentifier;
  final List<ShareItemModel> shareItems;

  DeleteAcksMessage({this.sessionIdentifier, this.shareItems});
}
