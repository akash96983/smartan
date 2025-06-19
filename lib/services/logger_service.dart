import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger();

  static void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void logInfo(String message) {
    _logger.i(message);
  }
}
