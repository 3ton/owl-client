import 'dart:typed_data';

import 'package:owl/share_room/enums/ShareItemAckedStatus.dart';
import 'package:owl/share_room/enums/ShareItemStatus.dart';
import 'package:owl/share_room/enums/ShareItemUnconfirmedReason.dart';
import 'package:owl/share_room/models/AckModel.dart';
import 'package:owl/share_room/models/RoomMembershipNotificationModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';

abstract class IShareRoomStorageService {
  Future createShareRoom(ShareRoomModel shareRoom);

  Future<List<ShareItemModel>> confirmShareRoomAndUpdateItems(
    String requestIdentifier,
    Uint8List roomIdentifier,
  );

  Future<bool> checkRoomAndCreateShareItem(ShareItemModel shareItem);

  Future confirmUploadingToFirebase(String requestIdentifier);

  Future<ShareRoomModel> getShareRoom(Uint8List roomIdentifier);

  Future createShareItem(ShareItemModel shareItem);

  Future confirmShareItem(String requestIdentifier, int timeOfCreation);

  Future changeItemsUnconfirmedReason(
    String requestIdentifier,
    ShareItemUnconfirmedReason reason,
  );

  Future changeItemsAckedStatuses(Iterable<ShareItemModel> shareItems);

  Future changeItemsAckedStatus(
    Uint8List roomIdentifier,
    int timeOfCreation,
    ShareItemAckedStatus ackedStatus,
  );

  Future<List<ShareItemModel>> getAllUnconfirmedAcks();

  Future confirmAcks(List<ShareItemModel> acks);

  Future createShareRooms(List<ShareRoomModel> shareRooms);
  Future createShareItems(List<ShareItemModel> shareItems);

  Future<List<ShareRoomModel>> getAllUnconfirmedRooms();

  Future<List<ShareItemModel>> getAllUnconfirmedItemsWithReasons(
    List<ShareItemUnconfirmedReason> reasons,
  );

  Future<List<ShareRoomModel>> getShareRoomsWithLatestItem(
      {bool confirmedOnly});

  Future<List<List<ShareItemModel>>> confirmShareRoomsAndUpdateItems(
    List<ShareRoomModel> shareRooms,
  );

  Future confirmShareItems(List<ShareItemModel> shareItems);

  Future applyRoomMembershipNotifications(
    List<RoomMembershipNotificationModel> notifications,
  );

  Future applyRoomMembershipNotification(
    RoomMembershipNotificationModel notification,
  );

  Future ackShareItems(List<AckModel> acks);

  Future<List<ShareItemStatus>> ackReadShareItems(List<AckModel> acks);
  
  Future<ShareItemStatus> ackShareItem(AckModel ack);

  Future<List<ShareItemModel>> getShareItemsFromRoom(
    Uint8List roomIdentifier, {
    bool initial,
    int offset,
  });

  List<ShareItemModel> addShareItemToCache(ShareItemModel shareItem);

  List<ShareItemModel> updateShareItemsStatusInCache(
    AckModel ack,
    ShareItemStatus status,
  );

  List<ShareItemModel> updateShareItemsStatusesInCache(
    List<AckModel> acks,
    List<ShareItemStatus> statuses,
  );

  List<ShareItemModel> updateShareItemsTimeInCache(
    int shareItemId,
    int timeOfCreation,
  );

  void resetShareItemsCache();

  Future createRoomMembershipNotification(
    String requestIdentifier,
    Uint8List roomIdentifier, {
    List<int> pals,
  });

  Future confirmRoomMembershipOperations(
    List<RoomMembershipNotificationModel> operations,
  );

  Future confirmRoomMembershipOperation(
    String requestIdentifier,
    Uint8List roomIdentifier, {
    List<int> pals,
  });

  Future<List<RoomMembershipNotificationModel>>
      getAllUnconfirmedRoomMembershipOperations();
}
