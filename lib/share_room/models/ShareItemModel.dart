import 'dart:typed_data';

import 'package:owl/share_room/enums/ShareItemAckedStatus.dart';
import 'package:owl/share_room/enums/ShareItemStatus.dart';
import 'package:owl/share_room/enums/ShareItemType.dart';
import 'package:owl/share_room/enums/ShareItemUnconfirmedReason.dart';
import 'package:owl/share_room/models/UserModel.dart';

class ShareItemModel {
  final String requestIdentifier;
  int id;
  final Uint8List roomIdentifier;
  final int creatorId;
  int timeOfCreation;
  final ShareItemType type;
  Uint8List content;
  final bool isConfirmed;
  final ShareItemUnconfirmedReason reason;
  ShareItemStatus status;
  final Map<String, int> palIdToStatus;
  final ShareItemAckedStatus ackedStatus;
  final bool isUploadedToFirebase;
  List<String> imageUrls;
  List<Uint8List> images;
  List<String> thumbnailFilePaths;
  List<Uint8List> thumbnails;
  final UserModel creator;

  ShareItemModel({
    this.requestIdentifier,
    this.id,
    this.roomIdentifier,
    this.creatorId,
    this.timeOfCreation,
    this.type,
    this.content,
    this.isConfirmed,
    this.reason,
    this.status,
    this.palIdToStatus,
    this.ackedStatus,
    this.isUploadedToFirebase,
    this.imageUrls,
    this.images,
    this.creator,
  });
}
