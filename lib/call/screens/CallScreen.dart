import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:owl/DIContainer.dart';
import 'package:owl/call/CallInfo.dart';
import 'package:owl/call/enums/MediaType.dart';
import 'package:owl/call/events/events.dart';
import 'package:owl/call/managers/CallManager.dart';

class CallScreen extends StatefulWidget {
  final CallInfo callInfo;

  CallScreen({Key key, this.callInfo}) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallManager _callManager = DIContainer.resolve<CallManager>();

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  StreamSubscription<dynamic> _callClosed$$;
  StreamSubscription<bool> _callGranted$$;
  StreamSubscription<MediaStream> _localStream$$;
  StreamSubscription<MediaStream> _remoteStream$$;
  StreamSubscription<bool> _callAccepted$$;

  bool _callGranted;
  bool _isInSession;

  @override
  void initState() {
    super.initState();

    if (widget.callInfo.isCaller) {
      _callManager.resetCallClosedSubject();

      _callManager.inEvent.add(
        InquireEvent(
          userId: widget.callInfo.user.id,
          media: widget.callInfo.media,
          screenShare: widget.callInfo.screenShare,
        ),
      );
    }

    _callGranted = false;
    _isInSession = false;

    _initRenderers();

    _callClosed$$ = _callManager.callClosed$.listen((_) {
      _callClosed$$.cancel();
      _callClosed$$ = null;
      Navigator.of(context).pop();
    });

    _localStream$$ = _callManager.localStream$.listen((stream) {
      if (widget.callInfo.media == MediaType.Video) {
        _localRenderer.srcObject = stream;
      }
    });

    _remoteStream$$ = _callManager.remoteStream$.listen((stream) {
      if (widget.callInfo.media == MediaType.Video) {
        _remoteRenderer.srcObject = stream;
      }
    });

    if (widget.callInfo.isCaller) {
      _callGranted$$ = _callManager.callGranted$.listen((granted) {
        if (granted) {
          setState(() {
            _callGranted = true;
          });
        } else {
          Navigator.of(context).pop();
        }
      });

      _callAccepted$$ = _callManager.callAccepted$.listen((accepted) {
        if (accepted) {
          setState(() {
            _isInSession = true;
          });
        } else {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();

    _callClosed$$?.cancel();
    _callGranted$$?.cancel();
    _localStream$$.cancel();
    _remoteStream$$.cancel();
    _callAccepted$$?.cancel();

    _callManager.resetStreamSubjects();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('===== Build CallScreen =====');

    return Scaffold(
      backgroundColor: Color(0xff000428),
      appBar: AppBar(
        title: Text(
          widget.callInfo.user.username != null
              ? utf8.decode(widget.callInfo.user.username)
              : widget.callInfo.user.id.toString(),
        ),
        backgroundColor: Color(0xff000428),
        elevation: 0.0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isInSession
          ? FloatingActionButton(
              heroTag: null,
              onPressed: () {
                _callManager.inEvent.add(EndCallEvent());
                Navigator.of(context).pop();
              },
              child: Icon(Icons.call_end),
              backgroundColor: Colors.pink,
            )
          : !widget.callInfo.isCaller
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FloatingActionButton(
                      heroTag: null,
                      onPressed: () {
                        _callManager.inEvent.add(AcceptCallEvent());
                        setState(() {
                          _isInSession = true;
                        });
                      },
                      child: Icon(
                        Icons.call,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 30.0),
                    FloatingActionButton(
                      heroTag: null,
                      onPressed: () {
                        _callManager.inEvent.add(DeclineCallEvent());
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.call_end,
                        color: Colors.red,
                      ),
                    ),
                  ],
                )
              : _callGranted
                  ? FloatingActionButton(
                      heroTag: null,
                      onPressed: () {
                        _callManager.inEvent.add(CancelCallEvent());
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.call_end,
                        color: Colors.red,
                      ),
                    )
                  : Text(
                    'Calling...',
                    style: TextStyle(color: Colors.white),
                  ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Container(
            child: _isInSession
                ? widget.callInfo.media == MediaType.Video
                    ? Stack(
                        children: <Widget>[
                          Positioned(
                            left: 0.0,
                            right: 0.0,
                            top: 0.0,
                            bottom: 0.0,
                            child: Container(
                              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              child: RTCVideoView(_remoteRenderer),
                              decoration: BoxDecoration(color: Colors.black54),
                            ),
                          ),
                          Positioned(
                            left: 20.0,
                            top: 20.0,
                            child: Container(
                              width: orientation == Orientation.portrait
                                  ? 90.0
                                  : 120.0,
                              height: orientation == Orientation.portrait
                                  ? 120.0
                                  : 90.0,
                              child: RTCVideoView(_localRenderer),
                              decoration: BoxDecoration(color: Colors.black54),
                            ),
                          ),
                        ],
                      )
                    : null
                : null,
          );
        },
      ),
    );
  }
}
