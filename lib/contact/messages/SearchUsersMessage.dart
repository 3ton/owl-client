import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class SearchUsersMessage extends Message {
  final Uint8List sessionIdentifier;
  final String emailUsernameId;

  SearchUsersMessage({this.sessionIdentifier, this.emailUsernameId});
}