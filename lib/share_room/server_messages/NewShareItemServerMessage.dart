import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/share_room/enums/ShareItemType.dart';

class NewShareItemServerMessage extends ServerMessage {
  final Uint8List roomIdentifier;
  final int creatorId;
  final int timeOfCreation;
  final ShareItemType type;
  final Uint8List content;

  NewShareItemServerMessage({
    this.roomIdentifier,
    this.creatorId,
    this.timeOfCreation,
    this.type,
    this.content,
  }) : super(
          messageCode: MessageCode.NewShareItem,
          isResponseToRequest: false,
        );
}
