import 'dart:typed_data';

import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/share_room/enums/ShareItemStatus.dart';
import 'package:owl/share_room/models/AckModel.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/UserModel.dart';

class CacheService {
  AccountModel _account;

  AccountModel loadAccount() => _account;

  void saveAccount(AccountModel account) {
    _account = account;
  }

  UserModel _user;

  UserModel loadUser() => _user;

  void saveUser(UserModel user) {
    _user = user;
  }

  final List<ShareItemModel> _shareItems = [];

  void resetShareItems() => _shareItems.clear();

  void addShareItems(List<ShareItemModel> shareItems) {
    _shareItems.insertAll(0, shareItems);
  }

  void addShareItem(ShareItemModel shareItem) {
    // @@NOTE:
    // In the absolute majority of cases a newly arrived share item
    // will have timeOfCreation bigger than timOfCreation of the last
    // cached share item, so we can just append it. But I think it is
    // possible for share items to arrive out of order, so we do not
    // take any chances. We don't need binary search here, linear in this
    // case will generally be faster.
    int index = 0;
    for (int i = _shareItems.length - 1; i >= 0; --i) {
      if (_shareItems[i].timeOfCreation < shareItem.timeOfCreation) {
        index = i + 1;
        break;
      }
    }
    _shareItems.insert(index, shareItem);
  }

  void updateShareItemsStatus(AckModel ack, ShareItemStatus status) {
    ShareItemModel shareItem = _shareItems.firstWhere(
      (shareItem) =>
          shareItem.timeOfCreation == ack.timeOfCreation &&
          _arrayEquals(shareItem.roomIdentifier, ack.roomIdentifier),
      orElse: () => null,
    );

    if (shareItem != null) {
      shareItem.status = status;
    }
  }

  void updateShareItemsStatuses(List<AckModel> acks, List<ShareItemStatus> statuses) {
    for (int i = 0; i < acks.length; ++i) {
      updateShareItemsStatus(acks[i], statuses[i]);
    }
  }

  void updateShareItemsTime(int shareItemId, int timeOfCreation) {
    ShareItemModel shareItem = _shareItems.firstWhere(
      (shareItem) => shareItem.id == shareItemId,
      orElse: () => null,
    );

    if (shareItem != null) {
      _shareItems.remove(shareItem);
      shareItem.timeOfCreation = timeOfCreation;
      addShareItem(shareItem);
    }
  }

  List<ShareItemModel> getShareItems() => _shareItems;

  bool _arrayEquals(Uint8List a, Uint8List b) {
    if (a == null || b == null) {
      return false;
    }

    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; ++i) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }
}
