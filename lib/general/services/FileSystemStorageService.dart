import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:owl/logging/services/LoggingService.dart';
import 'package:path_provider/path_provider.dart';

class FileSystemStorageService {
  final LoggingService _loggingService;

  Completer<String> _localPathLoaded;

  FileSystemStorageService(this._loggingService);

  Future<String> get _localPath async {
    if (_localPathLoaded == null) {
      _localPathLoaded = Completer<String>();
      String localPath = (await getApplicationDocumentsDirectory()).path;
      _localPathLoaded.complete(localPath);

      return localPath;
    }

    return _localPathLoaded.future;
  }

  Future saveFile(String filePath, Uint8List fileBytes) async {
    try {
      String localPath = await _localPath;
      var file = File('$localPath/$filePath');
      await (await file.create(recursive: true)).writeAsBytes(fileBytes);
    } catch (e, s) {
      _loggingService.log('$e\n$s');
      throw e;
    }
  }

  Future<Uint8List> loadFile(String filePath) async {
    try {
      String localPath = await _localPath;
      var file = File('$localPath/$filePath');
      
      return (await file.exists()) ? file.readAsBytes() : null;
    } catch (e, s) {
      _loggingService.log('$e\n$s');
      throw e;
    }
  }
}
