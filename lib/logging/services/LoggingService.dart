class LoggingService {
  final List<String> logs = [];

  void log(String message) {
    logs.add(message);
  }
}