import 'dart:async';

import 'dart:typed_data';

import 'package:owl/general/messages/Message.dart';
import 'package:owl/general/messages/MessageCode.dart';
import 'package:owl/general/server_messages/ServerMessage.dart';
import 'package:owl/general/services/IMessageConverterService.dart';
import 'package:owl/general/services/IMessageService.dart';
import 'package:uuid/uuid.dart';

import 'dart:collection';
import 'dart:io';

class MessageService implements IMessageService {
  final IMessageConverterService _messageConverterService;
  final Uuid _uuid;

  RawSocket _socket;

  final _Message _inputMessage = _Message();
  _Message _currentOutputMessage;
  final ListQueue<_Message> _outputMessageQueue = ListQueue<_Message>(10);

  final Map<String, Completer<ServerMessage>> _requestIdentifierToCompleter = {};

  void Function(ServerMessage) _onShareRoomServerMessage;

  set onShareRoomServerMessage(void Function(ServerMessage) value) {
    _onShareRoomServerMessage = value;
  }

  void Function(ServerMessage) _onWebRtcServerMessage;

  set onWebRtcServerMessage(void Function(ServerMessage) value) {
    _onWebRtcServerMessage = value;
  }

  MessageService(
    this._messageConverterService,
    this._uuid,
  ) {
    _connect('172.30.1.4', 50200);
  }

  void _connect(String host, int port) async {
    _socket = await RawSocket.connect(InternetAddress(host), port);
    _socket.writeEventsEnabled = false;
    _socket.listen(
      _onNewEventAvailable,
      onError: (error) => print('Error'),
      onDone: () => print('Done'),
    );
  }

  // @@TODO!!: What happens if connection is lost ? Error ?
  // What to do ? Complete all hanging completers ?
  void _onNewEventAvailable(RawSocketEvent event) {
    switch (event) {
      case RawSocketEvent.read:
        _receiveMessage();
        break;
      case RawSocketEvent.readClosed:
        print('readClosed');
        break;
      case RawSocketEvent.write:
        _sendMessage();
        break;
      case RawSocketEvent.closed:
        print('closed');
        break;
    }
  }

  void _receiveMessage() {
    Uint8List buffer;

    if (_inputMessage.length == -1) {
      buffer = _socket.read(4 - _inputMessage.payload.length);
      _inputMessage.payload.addAll(buffer);
      if (_inputMessage.payload.length == 4) {
        _inputMessage.length = Uint8List.fromList(_inputMessage.payload)
            .buffer
            .asByteData()
            .getInt32(0);
        _inputMessage.payload.clear();
      }
    } else {
      buffer = _socket.read(
        _inputMessage.length - _inputMessage.bytesTransferred,
      );
      _inputMessage.bytesTransferred += buffer.length;
      _inputMessage.payload.addAll(buffer);

      if (_inputMessage.bytesTransferred == _inputMessage.length) {
        var message = Uint8List.fromList(_inputMessage.payload);
        _inputMessage.reset();
        _handleMessage(message);
      }
    }
  }

  void _sendMessage() {
    if (_currentOutputMessage == null) {
      return;
    }

    int n = _socket.write(
      _currentOutputMessage.payload,
      _currentOutputMessage.bytesTransferred,
    );
    _currentOutputMessage.bytesTransferred += n;

    if (_currentOutputMessage.bytesTransferred ==
        _currentOutputMessage.length) {
      if (_outputMessageQueue.isNotEmpty) {
        _currentOutputMessage = _outputMessageQueue.removeFirst();
        _socket.writeEventsEnabled = true;
      } else {
        _currentOutputMessage = null;
        _socket.writeEventsEnabled = false;
      }
    } else {
      _socket.writeEventsEnabled = true;
    }
  }

  void disconnect() async {
    await _socket.close();
  }

  void _handleMessage(Uint8List message) {
    ServerMessage serverMessage = _messageConverterService.decodeServerMessage(message);
    if (serverMessage.isResponseToRequest) {
      Completer<ServerMessage> completer = _requestIdentifierToCompleter.remove(
        serverMessage.requestIdentifier,
      );
      completer?.complete(serverMessage);
    } else {
      switch (serverMessage.messageCode) {
        case MessageCode.WebRtcInquire:
        case MessageCode.WebRtcGrant:
        case MessageCode.WebRtcRefuse:
        case MessageCode.WebRtcOffer:
        case MessageCode.WebRtcAnswer:
        case MessageCode.WebRtcCandidate:
        case MessageCode.WebRtcDecline:
        case MessageCode.WebRtcEndSession:
        case MessageCode.WebRtcCancel:
          _onWebRtcServerMessage(serverMessage);
          break;
        default:
          _onShareRoomServerMessage(serverMessage);
          break;
      }
    }
  }

  @override
  Future<ServerMessage> sendMessage(Message msg, {bool responseExpected = true}) async {
    if (responseExpected && msg.requestIdentifier == null) {
      msg.requestIdentifier = _uuid.v4();
    }
    
    List<int> message = _messageConverterService.encodeMessage(msg);

    var outputMessage = _Message(payload: message, length: message.length);

    if (_currentOutputMessage == null) {
      _currentOutputMessage = outputMessage;
      _socket.writeEventsEnabled = true;
    } else {
      _outputMessageQueue.add(outputMessage);
    }

    if (responseExpected) {
      var completer = _requestIdentifierToCompleter[msg.requestIdentifier] =
          Completer<ServerMessage>();

      return await completer.future;
    }

    return null;
  }
}

class _Message {
  List<int> payload;
  int length;
  int bytesTransferred = 0;

  _Message({List<int> payload, int length = -1}) {
    this.payload = payload ?? [];
    this.length = length;
  }

  void reset() {
    payload.clear();
    length = -1;
    bytesTransferred = 0;
  }
}
