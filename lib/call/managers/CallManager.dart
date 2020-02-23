import 'package:flutter_webrtc/media_stream.dart';
import 'package:owl/call/CallInfo.dart';
import 'package:owl/call/events/events.dart';
import 'package:owl/call/services/ICallService.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:rxdart/rxdart.dart';

class CallManager {
  final ICallService _callService;
  final LoggingService _loggingService;

  final PublishSubject<CallEvent> _eventSubject = PublishSubject<CallEvent>();
  Sink<CallEvent> get inEvent => _eventSubject.sink;

  BehaviorSubject<dynamic> _callClosedSubject;
  Stream<dynamic> get callClosed$ => _callClosedSubject.stream;

  final PublishSubject<bool> _callGrantedSubject = PublishSubject<bool>();
  Stream<bool> get callGranted$ => _callGrantedSubject.stream;

  BehaviorSubject<MediaStream> _localStreamSubject =
      BehaviorSubject<MediaStream>();
  Stream<MediaStream> get localStream$ => _localStreamSubject.stream;

  BehaviorSubject<MediaStream> _remoteStreamSubject =
      BehaviorSubject<MediaStream>();
  Stream<MediaStream> get remoteStream$ => _remoteStreamSubject.stream;

  final PublishSubject<bool> _callAcceptedSubject = PublishSubject<bool>();
  Stream<bool> get callAccepted$ => _callAcceptedSubject.stream;

  final PublishSubject<CallInfo> _incomingCallSubject =
      PublishSubject<CallInfo>();
  Stream<CallInfo> get incomingCall$ => _incomingCallSubject.stream;

  CallManager(this._callService, this._loggingService) {
    _eventSubject.listen((event) {
      Future future;
      if (event is InquireEvent) {
        future = _inquire(event);
      } else if (event is CancelCallEvent) {
        future = _cancelCall();
      } else if (event is AcceptCallEvent) {
        future = _acceptCall();
      } else if (event is DeclineCallEvent) {
        future = _declineCall();
      } else if (event is EndCallEvent) {
        future = _endCall();
      }

      _logError(future);
    });

    _callService.event$.listen((event) {
      if (event is GrantCallEvent) {
        _notifyCallGranted();
      } else if (event is RefuseCallEvent) {
        _notifyCallRefused();
      } else if (event is LocalStreamEvent) {
        _addLocalStream(event);
      } else if (event is RemoteStreamEvent) {
        _addRemoteStream(event);
      } else if (event is RemoveRemoteStreamEvent) {
        _removeRemoteStream();
      } else if (event is IncomingCallEvent) {
        _incomingCall(event);
      } else if (event is CallAcceptedEvent) {
        _notifyCallAccepted();
      } else if (event is CallDeclinedEvent) {
        _notifyCallDeclined();
      } else if (event is EndCallEvent) {
        _closeCall();
      }
    });
  }

  void _logError(Future future) async {
    try {
      await future;
    } catch (e, s) {
      _loggingService.log('$e\n$s');
    }
  }

  Future _inquire(InquireEvent event) {
    return _callService.inquire(event.userId, event.media, event.screenShare);
  }

  Future _cancelCall() async {
    await _callService.cancelCall();
  }

  Future _acceptCall() async {
    await _callService.acceptCall();
  }

  Future _declineCall() async {
    await _callService.declineCall();
  }

  Future _endCall() async {
    await _callService.endCall();
  }

  void _notifyCallGranted() {
    _callGrantedSubject.add(true);
  }

  void _notifyCallRefused() {
    _callGrantedSubject.add(false);
  }

  void _addLocalStream(LocalStreamEvent event) {
    _localStreamSubject.add(event.stream);
  }

  void _addRemoteStream(RemoteStreamEvent event) {
    _remoteStreamSubject.add(event.stream);
  }

  void _removeRemoteStream() {
    _remoteStreamSubject.add(null);
  }

  void _incomingCall(IncomingCallEvent event) {
    resetCallClosedSubject();
    _incomingCallSubject.add(event.callInfo);
  }

  void _notifyCallAccepted() {
    _callAcceptedSubject.add(true);
  }

  void _notifyCallDeclined() {
    _callAcceptedSubject.add(false);
  }

  void _closeCall() {
    _callClosedSubject.add(null);
  }

  void resetCallClosedSubject() {
    _callClosedSubject?.close();
    _callClosedSubject = BehaviorSubject<dynamic>();
  }

  void resetStreamSubjects() {
    _localStreamSubject.close();
    _localStreamSubject = BehaviorSubject<MediaStream>();
    _remoteStreamSubject.close();
    _remoteStreamSubject = BehaviorSubject<MediaStream>();
  }
}
