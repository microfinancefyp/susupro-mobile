import 'package:logger/logger.dart';

extension LoggerExtension on Logger {
  void m(String message) {
    d(message);
  }
}
