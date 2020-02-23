import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class AddFirebaseUserMessage extends Message {
  final Uint8List sessionIdentifier;
  final String firebaseUserIdentifier;

  AddFirebaseUserMessage({this.sessionIdentifier, this.firebaseUserIdentifier});
}