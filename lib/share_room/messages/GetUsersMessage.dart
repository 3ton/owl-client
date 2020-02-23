import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class GetUsersMessage extends Message {
  final Uint8List sessionIdentifier;
  final List<int> users;

  GetUsersMessage({this.sessionIdentifier, this.users});
}