import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/webrtc.dart';
import 'package:owl/account/models/AccountModel.dart';
import 'package:owl/account/services/IAccountStorageService.dart';
import 'package:owl/call/CallInfo.dart';
import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/call/events/events.dart';
import 'package:owl/call/messages/WebRtcAnswerMessage.dart';
import 'package:owl/call/messages/WebRtcCandidateMessage.dart';
import 'package:owl/call/messages/WebRtcInquireMessage.dart';
import 'package:owl/call/messages/WebRtcMessage.dart';
import 'package:owl/call/messages/WebRtcOfferMessage.dart';
import 'package:owl/call/server_messages/WebRtcAnswerServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcCandidateServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcInquireServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcOfferServerMessage.dart';
import 'package:owl/call/server_messages/WebRtcServerMessage.dart';
import 'package:owl/call/services/ICallService.dart';
import 'package:owl/contact/services/ContactService.dart';
import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/general/services/IMessageService.dart';
import 'package:owl/logging/services/LoggingService.dart';
import 'package:owl/share_room/models/UserModel.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class WebRtcCallService implements ICallService {
  final IAccountStorageService _accountStorageService;
  final IMessageService _messageService;
  final ContactService _contactService;
  final LoggingService _loggingService;
  final Uuid _uuid;

  final PublishSubject<CallEvent> _eventSubject = PublishSubject<CallEvent>();
  @override
  Stream<CallEvent> get event$ => _eventSubject.stream;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {
        'url': 'stun:stun.l.google.com:19302',
      },
      /*
       * turn server configuration example.
      {
        'url': 'turn:123.45.67.89:3478',
        'username': 'change_to_real_user',
        'credential': 'change_to_real_secret'
      },
       */
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {
        'DtlsSrtpKeyAgreement': true,
      },
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  RTCPeerConnection _conn;
  MediaStream _localStream;
  List<RTCIceCandidate> _candidates;

  bool _isInSession = false;
  Uint8List _webRtcSessionIdentifier;
  MediaType _media;
  bool _screenShare;
  Completer<bool> _inquireTimedOut;
  Completer<bool> _offerTimedOut;

  UserModel _caller;
  WebRtcOfferServerMessage _offerServerMessage;

  bool _isCanceled = false;
  bool _hasFinishedInitializing = false;

  WebRtcCallService(
    this._accountStorageService,
    this._messageService,
    this._contactService,
    this._loggingService,
    this._uuid,
  ) {
    _messageService.onWebRtcServerMessage = _handleServerMessage;
  }

  void _logError(Future future) async {
    try {
      await future;
    } catch (e, s) {
      _loggingService.log('$e\n$s');
    }
  }

  void _close() {
    if (_conn != null) {
      _conn.onIceCandidate = null;
      _conn.onIceConnectionState = null;
      _conn.onAddStream = null;
      _conn.onRemoveStream = null;
      _conn.close();
      _conn = null;
    }

    _localStream?.dispose();
    _localStream = null;
    _candidates = null;
    _isInSession = false;
    _webRtcSessionIdentifier = null;
    _media = null;
    _screenShare = null;
    _inquireTimedOut = null;
    _offerTimedOut = null;
    _caller = null;
    _offerServerMessage = null;
    _isCanceled = false;
    _hasFinishedInitializing = false;
  }

  Future<MediaStream> _createStream(MediaType media, bool screenShare) async {
    if (media == MediaType.Audio) {
      screenShare = false;
    }

    var mediaConstraints = media == MediaType.Video
        ? {
            'audio': true,
            'video': {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            },
          }
        : {
            'audio': true,
            'video': false,
          };

    return screenShare
        ? await navigator.getDisplayMedia(mediaConstraints)
        : await navigator.getUserMedia(mediaConstraints);
  }

  void _onIceCandidate(RTCIceCandidate candidate) async {
    AccountModel account = await _accountStorageService.loadAccount();

    if (_webRtcSessionIdentifier == null) {
      return;
    }

    var msg = WebRtcCandidateMessage(
      sessionIdentifier: account.sessionIdentifier,
      webRtcSessionIdentifier: _webRtcSessionIdentifier,
      sdpMlineIndex: candidate.sdpMlineIndex,
      sdpMid: candidate.sdpMid,
      candidate: candidate.candidate,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);
    if (serverMessage.messageCode == MessageCode.WebRtcCandidateSuccess) {
      _loggingService.log('Candidate sent successfully');
      print('Candidate sent successfully');
      return;
    }

    _loggingService.log('WebRtcCandidate Error: ${serverMessage.messageCode}');
    print('WebRtcCandidate Error: ${serverMessage.messageCode}');
  }

  @override
  Future inquire(int userId, MediaType media, bool screenShare) async {
    if (_isInSession) {
      _eventSubject.add(EndCallEvent());
      return;
    }

    _isInSession = true;
    _webRtcSessionIdentifier = _uuid.v4buffer(Uint8List(16));
    _media = media;
    _screenShare = screenShare;

    AccountModel account = await _accountStorageService.loadAccount();

    var msg = WebRtcInquireMessage(
      sessionIdentifier: account.sessionIdentifier,
      userId: userId,
      webRtcSessionIdentifier: _webRtcSessionIdentifier,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);
    if (serverMessage.messageCode == MessageCode.WebRtcInquireSuccess) {
      _loggingService.log('Inquire Success');
      print('Inquire Success');

      _inquireTimedOut = Completer<bool>();

      bool timedOut = await Future.any([
        _inquireTimedOut.future,
        Future.delayed(Duration(seconds: 10), () => true),
      ]);

      if (timedOut) {
        _isInSession = false;
        _webRtcSessionIdentifier = null;
        _media = null;
        _screenShare = null;
        _inquireTimedOut = null;

        _eventSubject.add(EndCallEvent());
      }

      return;
    }

    _loggingService.log('Inquire Error: ${serverMessage.messageCode}');
    print('Inquire Error: ${serverMessage.messageCode}');

    _isInSession = false;
    _webRtcSessionIdentifier = null;
    _media = null;
    _screenShare = null;

    _eventSubject.add(EndCallEvent());
  }

  @override
  Future cancelCall() async {
    _isCanceled = true;

    if (!_hasFinishedInitializing) {
      return;
    }

    AccountModel account = await _accountStorageService.loadAccount();

    if (_webRtcSessionIdentifier != null) {
      var msg = WebRtcMessage(
        messageCode: MessageCode.WebRtcCancel,
        sessionIdentifier: account.sessionIdentifier,
        webRtcSessionIdentifier: _webRtcSessionIdentifier,
      );

      _messageService.sendMessage(msg, responseExpected: false);
    }

    _close();
  }

  @override
  Future acceptCall() async {
    if (_offerServerMessage == null) {
      // Accepted the call, but just a moment earlier Cancel message was received.
      return;
    }

    _media = _offerServerMessage.media;

    _localStream = await _createStream(_media, false);
    _eventSubject.add(LocalStreamEvent(stream: _localStream));

    _conn = await createPeerConnection(_iceServers, _config);
    _conn.addStream(_localStream);

    _conn.onIceCandidate = _onIceCandidate;

    _conn.onIceConnectionState = (state) {
      _loggingService.log('$state');

      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          _close();
          _eventSubject.add(EndCallEvent());
          break;
        default:
          break;
      }
    };

    _conn.onAddStream = (stream) {
      _eventSubject.add(RemoteStreamEvent(stream: stream));
    };

    _conn.onRemoveStream = (stream) {
      _eventSubject.add(RemoveRemoteStreamEvent());
    };

    await _conn.setRemoteDescription(
      RTCSessionDescription(_offerServerMessage.sdp, _offerServerMessage.type),
    );

    RTCSessionDescription sdp = await _conn.createAnswer(_constraints);
    _conn.setLocalDescription(sdp);

    if (_candidates != null) {
      _candidates.forEach((candidate) async {
        await _conn.addCandidate(candidate);
      });
      _candidates.clear();
    }

    _hasFinishedInitializing = true;

    if (_isCanceled) {
      // It's possible that some _conn.addCandidate from forEach are still executing.
      // In this case an exception will be thrown (?) (attempting to add candidate to a closed
      // connection or something). We can ignore it.
      endCall();
      _eventSubject.add(EndCallEvent());
      return;
    }

    AccountModel account = await _accountStorageService.loadAccount();

    if (_webRtcSessionIdentifier == null) {
      _eventSubject.add(EndCallEvent());
      return;
    }

    var msg = WebRtcAnswerMessage(
      sessionIdentifier: account.sessionIdentifier,
      webRtcSessionIdentifier: _webRtcSessionIdentifier,
      sdp: sdp.sdp,
      type: sdp.type,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);
    if (serverMessage.messageCode == MessageCode.WebRtcAnswerSuccess) {
      _loggingService.log('Answer sent successfully');
      print('Answer sent successfully');
      return;
    }

    _loggingService.log('WebRtcAnswer Error: ${serverMessage.messageCode}');
    print('WebRtcAnswer Error: ${serverMessage.messageCode}');

    _close();
    _eventSubject.add(EndCallEvent());
  }

  @override
  Future declineCall() async {
    if (_offerServerMessage == null) {
      // Declined the call, but just a moment earlier Cancel message was received.
      return;
    }

    _media = _offerServerMessage.media;

    AccountModel account = await _accountStorageService.loadAccount();

    if (_webRtcSessionIdentifier != null) {
      var msg = WebRtcMessage(
        messageCode: MessageCode.WebRtcDecline,
        sessionIdentifier: account.sessionIdentifier,
        webRtcSessionIdentifier: _webRtcSessionIdentifier,
      );

      _messageService.sendMessage(msg, responseExpected: false);
    }

    _candidates = null;
    _isInSession = false;
    _webRtcSessionIdentifier = null;
    _inquireTimedOut = null;
    _caller = null;
    _offerServerMessage = null;
  }

  @override
  Future endCall() async {
    // On the caller's side, hang up button becomes available when (and if)
    // caller receives an answer.

    // On the callee's side, hang up button becomes available right after callee presses accept,
    // which does not necessarily mean that accept's handler has fully executed already.

    _isCanceled = true;

    if (!_hasFinishedInitializing) {
      return;
    }

    AccountModel account = await _accountStorageService.loadAccount();

    if (_webRtcSessionIdentifier != null) {
      var msg = WebRtcMessage(
        messageCode: MessageCode.WebRtcEndSession,
        sessionIdentifier: account.sessionIdentifier,
        webRtcSessionIdentifier: _webRtcSessionIdentifier,
      );

      _messageService.sendMessage(msg, responseExpected: false);
    }

    _close();
  }

  Future _call() async {
    _localStream = await _createStream(_media, _screenShare);
    _eventSubject.add(LocalStreamEvent(stream: _localStream));

    _conn = await createPeerConnection(_iceServers, _config);
    _conn.addStream(_localStream);

    _conn.onIceCandidate = _onIceCandidate;

    _conn.onIceConnectionState = (state) {
      _loggingService.log('$state');

      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          _close();
          _eventSubject.add(EndCallEvent());
          break;
        default:
          break;
      }
    };

    _conn.onAddStream = (stream) {
      _eventSubject.add(RemoteStreamEvent(stream: stream));
    };

    _conn.onRemoveStream = (stream) {
      _eventSubject.add(RemoveRemoteStreamEvent());
    };

    RTCSessionDescription sdp = await _conn.createOffer(_constraints);
    _conn.setLocalDescription(sdp);

    _hasFinishedInitializing = true;

    if (_isCanceled) {
      // Callee granted us our inquiry, but as there will be no follow up, it will get timed out.
      _close();
      _eventSubject.add(EndCallEvent());
      return;
    }

    AccountModel account = await _accountStorageService.loadAccount();

    if (_webRtcSessionIdentifier == null) {
      _eventSubject.add(EndCallEvent());
      return;
    }

    var msg = WebRtcOfferMessage(
      sessionIdentifier: account.sessionIdentifier,
      webRtcsessionIdentifier: _webRtcSessionIdentifier,
      media: _media,
      sdp: sdp.sdp,
      type: sdp.type,
    );

    ServerMessage serverMessage = await _messageService.sendMessage(msg);
    // Offer is guaranteed to be sent before possible cancel message (by virtue of how
    // code is structured), but there is a possibility that cancel message will be
    // processed by a backend server before offer message. And there is also a possibility
    // that cancel message will arrive to the callee before offer message.
    if (serverMessage.messageCode == MessageCode.WebRtcOfferSuccess) {
      _loggingService.log('Offer sent successfully');
      print('Offer sent successfully');

      _offerTimedOut = Completer<bool>();

      bool timedOut = await Future.any([
        _offerTimedOut.future,
        Future.delayed(Duration(seconds: 30), () => true),
      ]);

      if (timedOut) {
        cancelCall();
        _eventSubject.add(EndCallEvent());
      }

      return;
    }

    _loggingService.log('Call Error: ${serverMessage.messageCode}');
    print('Call Error: ${serverMessage.messageCode}');

    _close();
    _eventSubject.add(EndCallEvent());
  }

  void _handleServerMessage(ServerMessage serverMessage) {
    Future future;
    if (serverMessage is WebRtcInquireServerMessage) {
      future = _handleWebRtcInquireServerMessage(serverMessage);
    } else if (serverMessage is WebRtcOfferServerMessage) {
      future = _handleWebRtcOfferServerMessage(serverMessage);
    } else if (serverMessage is WebRtcAnswerServerMessage) {
      future = _handleWebRtcAnswerServerMessage(serverMessage);
    } else if (serverMessage is WebRtcCandidateServerMessage) {
      future = _handleWebRtcCandidateServerMessage(serverMessage);
    } else if (serverMessage is WebRtcServerMessage) {
      if (serverMessage.messageCode == MessageCode.WebRtcGrant) {
        future = _handleWebRtcGrantServerMessage(serverMessage);
      } else if (serverMessage.messageCode == MessageCode.WebRtcRefuse) {
        future = _handleWebRtcRefuseServerMessage(serverMessage);
      } else if (serverMessage.messageCode == MessageCode.WebRtcDecline) {
        future = _handleWebRtcDeclineServerMessage(serverMessage);
      } else if (serverMessage.messageCode == MessageCode.WebRtcEndSession) {
        future = _handleWebRtcEndSessionServerMessage(serverMessage);
      } else if (serverMessage.messageCode == MessageCode.WebRtcCancel) {
        future = _handleWebRtcCancelServerMessage(serverMessage);
      }
    }

    _logError(future);
  }

  bool _isCurrentSession(Uint8List webRtcSessionIdentifier) => _arrayEquals(
        _webRtcSessionIdentifier,
        webRtcSessionIdentifier,
      );

  Future _handleWebRtcInquireServerMessage(
    WebRtcInquireServerMessage serverMessage,
  ) async {
    MessageCode messageCode;
    if (!_isInSession) {
      messageCode = MessageCode.WebRtcGrant;
      _isInSession = true;
      _webRtcSessionIdentifier = serverMessage.webRtcSessionIdentifier;
      _caller = await _contactService.getUser(serverMessage.userId) ??
          UserModel(id: serverMessage.userId);
    } else {
      messageCode = MessageCode.WebRtcRefuse;
    }

    AccountModel account = await _accountStorageService.loadAccount();

    var msg = WebRtcMessage(
      messageCode: messageCode,
      sessionIdentifier: account.sessionIdentifier,
      webRtcSessionIdentifier: serverMessage.webRtcSessionIdentifier,
    );

    _messageService.sendMessage(msg, responseExpected: false);

    if (messageCode == MessageCode.WebRtcGrant) {
      _inquireTimedOut = Completer<bool>();

      try {
        // If cancel message arrives before offer message and grant hasn't timed out yet,
        // we have to null everything, instead of simply calling _inquireTimedOut.complete(true),
        // because there is a veeery remote possibility that offer message will sneak in between
        // calling complete and actual execution of the code here. If it sneaks in, our cancel
        // request will get ignored. And we also can't null everything and then call
        // _inquireTimedOut(true) or simply wait until it times out naturally, because there
        // is a possibility that after nulling everything but before code here is executed
        // some other inquiry is received. We don't want to null fields that we no longer
        // have ownership of.

        bool timedOut = await Future.any([
          _inquireTimedOut.future,
          Future.delayed(Duration(seconds: 10), () => true)
        ]);

        if (timedOut) {
          _isInSession = false;
          _webRtcSessionIdentifier = null;
          _caller = null;
          _inquireTimedOut = null;
        }
      } catch (e, s) {
        _loggingService.log('$e\n$s');
      }
    }
  }

  Future _handleWebRtcGrantServerMessage(
    WebRtcServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    // If got here, inquire hasn't timed out yet.
    _inquireTimedOut.complete(false);

    _eventSubject.add(GrantCallEvent());
    _call();
  }

  Future _handleWebRtcRefuseServerMessage(
    WebRtcServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    // If got here, inquire hasn't timed out yet.
    _inquireTimedOut.complete(false);

    _isInSession = false;
    _webRtcSessionIdentifier = null;
    _media = null;
    _screenShare = null;
    _inquireTimedOut = null;

    _eventSubject.add(RefuseCallEvent());
  }

  Future _handleWebRtcOfferServerMessage(
    WebRtcOfferServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    // If got here, grant hasn't timed out yet and call wasn't canceled.

    _inquireTimedOut.complete(false);

    _offerServerMessage = serverMessage;

    _eventSubject.add(
      IncomingCallEvent(
        callInfo: CallInfo(
          user: _caller,
          isCaller: false,
          media: serverMessage.media,
        ),
      ),
    );
  }

  Future _handleWebRtcAnswerServerMessage(
    WebRtcAnswerServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    // If got here, offer hasn't timed out yet.

    _offerTimedOut.complete(false);

    await _conn.setRemoteDescription(
      RTCSessionDescription(serverMessage.sdp, serverMessage.type),
    );

    _eventSubject.add(CallAcceptedEvent());
  }

  Future _handleWebRtcCandidateServerMessage(
    WebRtcCandidateServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    // Candidates can start arriving to the callee before connection was actually
    // initialized. In fact they will most likely start arriving before callee
    // makes his decision whether to accept or decline the call.

    var candidate = RTCIceCandidate(
      serverMessage.candidate,
      serverMessage.sdpMid,
      serverMessage.sdpMlineIndex,
    );

    if (_conn == null) {
      _candidates = _candidates ?? [];
      _candidates.add(candidate);
    } else {
      await _conn.addCandidate(candidate);
    }
  }

  Future _handleWebRtcDeclineServerMessage(
    WebRtcServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    // If got here, offer hasn't timed out yet.
    _offerTimedOut.complete(false);

    _loggingService.log('Call declined');

    _close();
    _eventSubject.add(CallDeclinedEvent());
  }

  Future _handleWebRtcEndSessionServerMessage(
    WebRtcServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    _close();
    _eventSubject.add(EndCallEvent());
  }

  Future _handleWebRtcCancelServerMessage(
    WebRtcServerMessage serverMessage,
  ) async {
    if (!_isCurrentSession(serverMessage.webRtcSessionIdentifier)) {
      return;
    }

    if (_offerServerMessage == null) {
      // Deal with a slight possibility that a cancel message arrives before an offer message.
      // If got here, grant hasn't timed out yet.
      _isInSession = false;
      _webRtcSessionIdentifier = null;
      _caller = null;
      Completer<bool> inquireTimedOut = _inquireTimedOut;
      _inquireTimedOut = null;
      inquireTimedOut.completeError(TimeoutException('Canceled'));

      return;
    }

    if (_media == null) {
      // Accept and decline set _media before the first await call, so _media field can serve
      // as a simple indicator whether accept/decline's handler has already started executing
      // or not.
      // If got here, offer already received and _inquireTimedOut can be nulled safely.
      _isInSession = false;
      _webRtcSessionIdentifier = null;
      _inquireTimedOut = null;
      _caller = null;
      _offerServerMessage = null;

      _eventSubject.add(EndCallEvent());

      return;
    }

    // Accept/decline's handler has already started executing.

    _isCanceled = true;

    if (!_hasFinishedInitializing) {
      return;
    }

    _close();
    _eventSubject.add(EndCallEvent());
  }

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
