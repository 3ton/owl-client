import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/call/events/events.dart';

abstract class ICallService {
  Future inquire(int userId, MediaType media, bool screenShare);
  Future cancelCall();
  Future acceptCall();
  Future declineCall();
  Future endCall();
  Stream<CallEvent> get event$;
}