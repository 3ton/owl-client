import 'dart:typed_data';

import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/UserModel.dart';

abstract class ShareRoomEvent {}

class JoinEvent extends ShareRoomEvent {}

class GetShareRoomsWithLatestItemEvent extends ShareRoomEvent {}

class CreateShareRoomEvent extends ShareRoomEvent {
  final Set<int> users;
  final String roomName;

  CreateShareRoomEvent({this.users, this.roomName});
}

class InitializeRoomEvent extends ShareRoomEvent {
  final Uint8List roomIdentifier;

  InitializeRoomEvent({this.roomIdentifier});
}

class CloseRoomEvent extends ShareRoomEvent {}

class AttachImagesEvent extends ShareRoomEvent {
  final List<Asset> imageAssets;

  AttachImagesEvent({this.imageAssets});
}

class CreateShareItemEvent extends ShareRoomEvent {
  final String text;

  CreateShareItemEvent({this.text});
}

class GetShareItemsFromRoomEvent extends ShareRoomEvent {
  final int offset;

  GetShareItemsFromRoomEvent({this.offset});
}

class ShareRoomInvitationEvent extends ShareRoomEvent {}

class NewShareItemEvent extends ShareRoomEvent {
  final List<ShareItemModel> shareItems;

  NewShareItemEvent({this.shareItems});
}

class IsTypingEvent extends ShareRoomEvent {
  final UserModel user;
  final Uint8List roomIdentifier;

  IsTypingEvent({this.user, this.roomIdentifier});
}