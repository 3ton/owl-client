import 'dart:typed_data';

import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/share_room/events/events.dart';
import 'package:owl/share_room/models/ShareItemModel.dart';
import 'package:owl/share_room/models/ShareRoomModel.dart';
import 'package:owl/share_room/models/UserModel.dart';
import 'package:owl/share_room/services/IShareRoomStorageService.dart';
import 'package:owl/share_room/services/ShareRoomService.dart';
import 'package:rxdart/rxdart.dart';

class ShareRoomManager {
  final ShareRoomService _shareRoomService;
  final IShareRoomStorageService _shareRoomStorageService;
  final LoggingService _loggingService;

  final PublishSubject<ShareRoomEvent> _eventSubject =
      PublishSubject<ShareRoomEvent>();
  Sink<ShareRoomEvent> get inEvent => _eventSubject.sink;

  final PublishSubject<IsTypingEvent> _isTypingEventSubject =
      PublishSubject<IsTypingEvent>();

  final PublishSubject<dynamic> _joinSubject = PublishSubject<dynamic>();
  Stream<dynamic> get join$ => _joinSubject.stream;

  final BehaviorSubject<List<ShareRoomModel>>
      _getShareRoomsWithLatestItemSubject =
      BehaviorSubject<List<ShareRoomModel>>();
  Stream<List<ShareRoomModel>> get getShareRoomsWithLatestItem$ =>
      _getShareRoomsWithLatestItemSubject.stream;

  BehaviorSubject<List<ShareItemModel>> _getShareItemsFromRoomSubject =
      BehaviorSubject<List<ShareItemModel>>();
  Stream<List<ShareItemModel>> get getShareItemsFromRoom$ =>
      _getShareItemsFromRoomSubject.stream;

  final PublishSubject<List<UserModel>> _notifyTypingSubject =
      PublishSubject<List<UserModel>>();
  Stream<List<UserModel>> get notifyTyping$ => _notifyTypingSubject.stream;

  // [[user future] [user future] [user future] ...]
  final List<List<dynamic>> userAndFuturePairs = List<List<dynamic>>();

  ShareRoomManager(
    this._shareRoomService,
    this._shareRoomStorageService,
    this._loggingService,
  ) {
    _eventSubject.listen((event) {
      Future future;
      if (event is JoinEvent) {
        future = _join();
      } else if (event is GetShareRoomsWithLatestItemEvent) {
        future = _getShareRoomsWithLatestItem();
      } else if (event is InitializeRoomEvent) {
        future = _initializeRoom(event);
      } else if (event is CloseRoomEvent) {
        future = _closeRoom();
      } else if (event is GetShareItemsFromRoomEvent) {
        future = _getShareItemsFromRoom(event);
      } else if (event is CreateShareRoomEvent) {
        future = _createShareRoom(event);
      } else if (event is CreateShareItemEvent) {
        future = _createShareItem(event);
      } else if (event is AttachImagesEvent) {
        future = _attachImages(event);
      } else if (event is IsTypingEvent) {
        _isTypingEventSubject.add(event);
      }

      _logError(future);
    });

    _isTypingEventSubject.stream
        .debounceTime(Duration(milliseconds: 200))
        .listen((_) {
      _shareRoomService.notifyTyping();
    });

    _shareRoomService.event$.listen((event) {
      Future future;
      if (event is ShareRoomInvitationEvent) {
        future = _getShareRoomsWithLatestItem();
      } else if (event is NewShareItemEvent) {
        future = _notifyNewShareItem(event);
      } else if (event is IsTypingEvent) {
        future = _notifyTyping(event);
      }

      _logError(future);
    });
  }

  void _logError(Future future) async {
    try {
      await future;
    } catch (e, s) {
      _loggingService.log('$e\n$s');
    }
  }

  Future _join() async {
    await _shareRoomService.join();
    _joinSubject.add(null);
  }

  Future _getShareRoomsWithLatestItem() async {
    List<ShareRoomModel> shareRooms =
        await _shareRoomService.getShareRoomsWithLatestItem();
    _getShareRoomsWithLatestItemSubject.add(shareRooms);
  }

  Future _initializeRoom(InitializeRoomEvent event) async {
    List<ShareItemModel> shareItems =
        await _shareRoomService.initializeRoom(event.roomIdentifier);
    _getShareItemsFromRoomSubject.add(shareItems);
  }

  Future _closeRoom() async {
    _shareRoomService.closeRoom();
    _getShareItemsFromRoomSubject.close();
    _getShareItemsFromRoomSubject = BehaviorSubject<List<ShareItemModel>>();
  }

  Future _createShareRoom(CreateShareRoomEvent event) async {
    var pals = event.users.toList();
    await _shareRoomService.createShareRoom(event.roomName ?? 'room', pals);

    _getShareRoomsWithLatestItem();
  }

  Future _getShareItemsFromRoom(GetShareItemsFromRoomEvent event) async {
    Uint8List roomIdentifier = _shareRoomService.currentRoomIdentifier;
    List<ShareItemModel> shareItems =
        await _shareRoomStorageService.getShareItemsFromRoom(
      roomIdentifier,
      initial: false,
      offset: event.offset,
    );

    if (_shareRoomService.isCurrentRoom(roomIdentifier)) {
      _getShareItemsFromRoomSubject.add(shareItems);
    }
  }

  Future _createShareItem(CreateShareItemEvent event) async {
    if (event.text != null && event.text.isNotEmpty) {
      _shareRoomService.attachText(event.text);
    }

    await _shareRoomService.createShareItem();
  }

  Future _notifyNewShareItem(NewShareItemEvent event) async {
    if (_shareRoomService.isCurrentRoom(event.shareItems[0].roomIdentifier)) {
      _getShareItemsFromRoomSubject.add(event.shareItems);
    }
  }

  Future _attachImages(AttachImagesEvent event) async {
    await _shareRoomService.attachImages(event.imageAssets);
  }

  // @@NOTE: Should find better way to do it. This is buggy.
  Future _notifyTyping(IsTypingEvent event) async {
    UserModel typingUser = event.user;
    if (_shareRoomService.isCurrentRoom(event.roomIdentifier)) {
      var userAndFuture = userAndFuturePairs.firstWhere(
        (userAndFuture) => (userAndFuture[0] as UserModel).id == typingUser.id,
        orElse: () => null,
      );

      var future = Future.delayed(Duration(seconds: 1));
      if (userAndFuture != null) {
        userAndFuture[1] = future;
      } else {
        userAndFuture = [typingUser, future];
        userAndFuturePairs.add(userAndFuture);
      }

      _notifyTypingSubject.add(
        userAndFuturePairs
            .map((userAndFuture) => userAndFuture[0] as UserModel)
            .toList(),
      );

      await future;

      if (userAndFuture[1] == future) {
        userAndFuturePairs.remove(userAndFuture);

        _notifyTypingSubject.add(
          userAndFuturePairs
              .map((userAndFuture) => userAndFuture[0] as UserModel)
              .toList(),
        );
      }
    } /*else if (_shareRoomService.currentRoomIdentifier == null) {
      List<ShareRoomModel> shareRooms =
          _getShareRoomsWithLatestItemSubject.value;

      var shareRoom = shareRooms.firstWhere(
        (shareRoom) => _arrayEquals(shareRoom.identifier, event.roomIdentifier),
        orElse: () => null,
      );

      if (shareRoom != null) {
        shareRoom.currentlyTypingGuy = event.user;
        _getShareRoomsWithLatestItemSubject.add(shareRooms);

        await Future.delayed(Duration(seconds: 2));

        if (shareRoom.currentlyTypingGuy == typingUser) {
          shareRoom.currentlyTypingGuy = null;
          _getShareRoomsWithLatestItemSubject.add(shareRooms);
        }
      }
    }*/
  }

  // @@TODO: Move all _arrayEquals and _logError to mixins or smth. Extension method for Uint8List?
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
