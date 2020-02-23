import 'dart:typed_data';

import 'package:owl/general/services/IStorageService.dart';
import 'package:owl/share_room/enums/ShareItemAckedStatus.dart';
import 'package:owl/share_room/enums/ShareItemStatus.dart';
import 'package:owl/share_room/enums/ShareItemUnconfirmedReason.dart';
import 'package:owl/share_room/models/AckModel.dart';
import 'package:owl/share_room/models/RoomMembershipNotificationModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';
import 'package:owl/share_room/services/IShareRoomStorageService.dart';

class ShareRoomStorageService implements IShareRoomStorageService {
  final IStorageService _storageService;

  ShareRoomStorageService(this._storageService);

  @override
  Future createShareRoom(ShareRoomModel shareRoom) {
    return _storageService.createShareRoom(shareRoom);
  }

  @override
  Future<List<ShareItemModel>> confirmShareRoomAndUpdateItems(
    String requestIdentifier,
    Uint8List roomIdentifier,
  ) {
    return _storageService.confirmShareRoomAndUpdateItems(
        requestIdentifier, roomIdentifier);
  }

  @override
  Future<bool> checkRoomAndCreateShareItem(ShareItemModel shareItem) {
    return _storageService.checkRoomAndCreateShareItem(shareItem);
  }

  @override
  Future confirmUploadingToFirebase(String requestIdentifier) {
    return _storageService.confirmUploadingToFirebase(
      requestIdentifier,
    );
  }

  @override
  Future<ShareRoomModel> getShareRoom(Uint8List roomIdentifier) {
    return _storageService.getShareRoom(roomIdentifier);
  }

  @override
  Future createShareItem(ShareItemModel shareItem) {
    return _storageService.createShareItem(shareItem);
  }

  @override
  Future confirmShareItem(String requestIdentifier, int timeOfCreation) {
    return _storageService.confirmShareItem(
        requestIdentifier, timeOfCreation);
  }

  @override
  Future changeItemsUnconfirmedReason(
    String requestIdentifier,
    ShareItemUnconfirmedReason reason,
  ) {
    return _storageService.changeItemsUnconfirmedReason(
        requestIdentifier, reason);
  }

  @override
  Future changeItemsAckedStatuses(Iterable<ShareItemModel> shareItems) {
    return _storageService.changeItemsAckedStatuses(shareItems);
  }

  @override
  Future changeItemsAckedStatus(
    Uint8List roomIdentifier,
    int timeOfCreation,
    ShareItemAckedStatus ackedStatus,
  ) {
    return _storageService.changeItemsAckedStatus(
      roomIdentifier,
      timeOfCreation,
      ackedStatus,
    );
  }

  @override
  Future<List<ShareItemModel>> getAllUnconfirmedAcks() {
    return _storageService.getAllUnconfirmedAcks();
  }

  @override
  Future confirmAcks(List<ShareItemModel> acks) {
    return _storageService.confirmAcks(acks);
  }

  @override
  Future createShareRooms(List<ShareRoomModel> shareRooms) {
    return _storageService.createShareRooms(shareRooms);
  }

  @override
  Future createShareItems(List<ShareItemModel> shareItems) {
    return _storageService.createShareItems(shareItems);
  }

  @override
  Future<List<ShareRoomModel>> getShareRoomsWithLatestItem({
    bool confirmedOnly,
  }) {
    return _storageService.getShareRoomsWithLatestItem(
      confirmedOnly: confirmedOnly,
    );
  }

  @override
  Future<List<ShareItemModel>> getShareItemsFromRoom(
    Uint8List roomIdentifier, {
    bool initial,
    int offset,
  }) {
    return _storageService.getShareItemsFromRoom(
      roomIdentifier,
      initial: initial,
      offset: offset,
    );
  }

  @override
  List<ShareItemModel> addShareItemToCache(ShareItemModel shareItem) {
    return _storageService.addShareItemToCache(shareItem);
  }

  @override
  List<ShareItemModel> updateShareItemsStatusInCache(
    AckModel ack,
    ShareItemStatus status,
  ) {
    return _storageService.updateShareItemsStatusInCache(ack, status);
  }

  @override
  List<ShareItemModel> updateShareItemsStatusesInCache(
    List<AckModel> acks,
    List<ShareItemStatus> statuses,
  ) {
    return _storageService.updateShareItemsStatusesInCache(acks, statuses);
  }

  @override
  List<ShareItemModel> updateShareItemsTimeInCache(
    int shareItemId,
    int timeOfCreation,
  ) {
    return _storageService.updateShareItemsTimeInCache(
      shareItemId,
      timeOfCreation,
    );
  }

  @override
  void resetShareItemsCache() {
    return _storageService.resetShareItemsCache();
  }

  @override
  Future<List<List<ShareItemModel>>> confirmShareRoomsAndUpdateItems(
    List<ShareRoomModel> shareRooms,
  ) {
    return _storageService.confirmShareRoomsAndUpdateItems(shareRooms);
  }

  @override
  Future confirmShareItems(List<ShareItemModel> shareItems) {
    return _storageService.confirmShareItems(shareItems);
  }

  @override
  Future applyRoomMembershipNotifications(
    List<RoomMembershipNotificationModel> notifications,
  ) {
    return _storageService
        .applyRoomMembershipNotifications(notifications);
  }

  @override
  Future applyRoomMembershipNotification(
    RoomMembershipNotificationModel notification,
  ) {
    return _storageService.applyRoomMembershipNotification(notification);
  }

  @override
  Future ackShareItems(List<AckModel> acks) {
    return _storageService.ackShareItems(acks);
  }

  @override
  Future<List<ShareItemStatus>> ackReadShareItems(List<AckModel> acks) {
    return _storageService.ackReadShareItems(acks);
  }

  @override
  Future<ShareItemStatus> ackShareItem(AckModel ack) {
    return _storageService.ackShareItem(ack);
  }

  @override
  Future<List<ShareItemModel>> getAllUnconfirmedItemsWithReasons(
    List<ShareItemUnconfirmedReason> reasons,
  ) {
    return _storageService.getAllUnconfirmedItemsWithReasons(
      reasons,
    );
  }

  @override
  Future<List<ShareRoomModel>> getAllUnconfirmedRooms() {
    return _storageService.getAllUnconfirmedRooms();
  }

  @override
  Future createRoomMembershipNotification(
    String requestIdentifier,
    Uint8List roomIdentifier, {
    List<int> pals,
  }) {
    return _storageService.createRoomMembershipNotification(
      requestIdentifier,
      roomIdentifier,
      pals: pals,
    );
  }

  @override
  Future confirmRoomMembershipOperations(
    List<RoomMembershipNotificationModel> operations,
  ) {
    return _storageService.confirmRoomMembershipOperations(operations);
  }

  @override
  Future confirmRoomMembershipOperation(
    String requestIdentifier,
    Uint8List roomIdentifier, {
    List<int> pals,
  }) {
    return _storageService.confirmRoomMembershipOperation(
      requestIdentifier,
      roomIdentifier,
      pals: pals,
    );
  }

  @override
  Future<List<RoomMembershipNotificationModel>>
      getAllUnconfirmedRoomMembershipOperations() {
    return _storageService.getAllUnconfirmedRoomMembershipOperations();
  }
}
