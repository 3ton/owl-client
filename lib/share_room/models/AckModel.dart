import 'dart:typed_data';

import 'package:owl/general/messages/MessageCode.dart';

class AckModel {
  final MessageCode messageCode;
  final int palId;
  final Uint8List roomIdentifier;
  final int timeOfCreation;
  final List<int> notReceivedPals;
  final List<int> notReadPals;

  AckModel({
    this.messageCode,
    this.palId,
    this.roomIdentifier,
    this.timeOfCreation,
    this.notReceivedPals,
    this.notReadPals,
  });
}
