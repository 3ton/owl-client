import 'package:flutter_webrtc/media_stream.dart';
import 'package:owl/call/CallInfo.dart';
import 'package:owl/call/enums/MediaType.dart';

abstract class CallEvent {}

class InquireEvent extends CallEvent {
  final int userId;
  final MediaType media;
  final bool screenShare;

  InquireEvent({this.userId, this.media, this.screenShare});
}

class GrantCallEvent extends CallEvent {}

class RefuseCallEvent extends CallEvent {}

class CancelCallEvent extends CallEvent {}

class AcceptCallEvent extends CallEvent {}

class DeclineCallEvent extends CallEvent {}

class CallAcceptedEvent extends CallEvent {}

class CallDeclinedEvent extends CallEvent {}

class EndCallEvent extends CallEvent {}

class LocalStreamEvent extends CallEvent {
  final MediaStream stream;

  LocalStreamEvent({this.stream});
}

class RemoteStreamEvent extends CallEvent {
  final MediaStream stream;

  RemoteStreamEvent({this.stream});
}

class RemoveRemoteStreamEvent extends CallEvent {}

class IncomingCallEvent extends CallEvent {
  final CallInfo callInfo;

  IncomingCallEvent({this.callInfo});
}