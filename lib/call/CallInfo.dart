import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/share_room/models/UserModel.dart';

class CallInfo {
  final UserModel user;
  final bool isCaller;
  final MediaType media;
  final bool screenShare;

  CallInfo({this.user, this.isCaller, this.media, this.screenShare});
}