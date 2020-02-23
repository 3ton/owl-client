import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart';

class ThumbnailGeneratorService {
  SendPort _sendPort;
  final Queue<Completer<Uint8List>> _completerQueue =
      Queue<Completer<Uint8List>>();

  ThumbnailGeneratorService() {
    var receivePort = ReceivePort();
    Isolate.spawn(startWorker, receivePort.sendPort);

    receivePort.listen((data) {
      if (data is SendPort) {
        _sendPort = data;
      } else {
        var completer = _completerQueue.removeFirst();
        completer.complete(data);
      }
    });
  }

  static void startWorker(SendPort sendPort) async {
    var receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((imageBytes) {
      Image image = decodeImage(imageBytes);
      Image thumbnail = copyResize(image, width: min(image.width, 200));

      sendPort.send(Uint8List.fromList(encodePng(thumbnail)));
    });
  }

  Future<Uint8List> generate(Uint8List imageBytes) {
    var completer = Completer<Uint8List>();
    _completerQueue.add(completer);
    
    _sendPort.send(imageBytes);

    return completer.future;
  }
}
