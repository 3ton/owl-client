import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';

class ConfirmEmailMessage extends Message {
  final Uint8List userIdentifier;
  final String confirmationCode;

  ConfirmEmailMessage({this.userIdentifier, this.confirmationCode});
}
