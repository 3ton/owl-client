import 'package:owl/logging/services/LoggingService.dart';
import 'package:rxdart/rxdart.dart';

class LoggingManager {
  final LoggingService _loggingService;

  final PublishSubject<List<String>> _getLogsSubject = PublishSubject<List<String>>();
  Stream<List<String>> get getLogs$ => _getLogsSubject.stream;

  LoggingManager(this._loggingService);

  void getLogs() {
    _getLogsSubject.add(_loggingService.logs);
  }
}