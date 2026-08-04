import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final tagStr = tag != null ? '[$tag] ' : '';
      print('PocketMedic $timestamp $tagStr$message');
    }
  }

  static void error(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final tagStr = tag != null ? '[$tag] ' : '';
      print('PocketMedic $timestamp ERROR $tagStr$message${error != null ? '\n$error' : ''}');
    }
  }

  static void info(String message) => log(message, tag: 'INFO');
  static void debug(String message) => log(message, tag: 'DEBUG');
  static void warn(String message) => log(message, tag: 'WARN');
}
