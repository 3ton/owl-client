import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/share_room/models/AckModel.dart';
import 'package:owl/share_room/models/RoomMembershipNotificationModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';

class JoinedServerMessage extends ServerMessage {
  final List<ShareRoomModel> confirmedRooms;
  final List<ShareItemModel> confirmedItems;
  final List<RoomMembershipNotificationModel> notifications;
  final List<AckModel> acks;
  final List<ShareRoomModel> shareRooms;
  final List<ShareItemModel> shareItems;

  JoinedServerMessage({
    String requestIdentifier,
    this.confirmedRooms,
    this.confirmedItems,
    this.notifications,
    this.acks,
    this.shareRooms,
    this.shareItems,
  }) : super(
          messageCode: MessageCode.Joined,
          isResponseToRequest: true,
          requestIdentifier: requestIdentifier,
        );
}
