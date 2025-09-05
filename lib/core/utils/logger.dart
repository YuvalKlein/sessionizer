import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (!kReleaseMode) {
      final fullMessage = data != null ? '$message | Data: $data' : message;
      _logger.d(fullMessage, error: error ?? '', stackTrace: stackTrace);
    }
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (!kReleaseMode) {
      final fullMessage = data != null ? '$message | Data: $data' : message;
      _logger.i(fullMessage, error: error ?? '', stackTrace: stackTrace);
    }
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (!kReleaseMode) {
      final fullMessage = data != null ? '$message | Data: $data' : message;
      _logger.w(fullMessage, error: error ?? '', stackTrace: stackTrace);
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (!kReleaseMode) {
      final fullMessage = data != null ? '$message | Data: $data' : message;
      _logger.e(fullMessage, error: error ?? '', stackTrace: stackTrace);
    }
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (!kReleaseMode) {
      final fullMessage = data != null ? '$message | Data: $data' : message;
      _logger.f(fullMessage, error: error ?? '', stackTrace: stackTrace);
    }
  }

  // Specific logging methods for debugging flashing issues
  static void widgetBuild(String widgetName, {Map<String, dynamic>? data}) {
    debug('🔨 WIDGET BUILD: $widgetName', data: data);
  }

  static void stateChange(String blocName, String event, {Map<String, dynamic>? data}) {
    debug('🔄 STATE CHANGE: $blocName - $event', data: data);
  }

  static void navigation(String from, String to, {Map<String, dynamic>? data}) {
    debug('🧭 NAVIGATION: $from -> $to', data: data);
  }

  static void blocEvent(String blocName, String event, {Map<String, dynamic>? data}) {
    debug('📡 BLOC EVENT: $blocName - $event', data: data);
  }

  static void blocState(String blocName, String state, {Map<String, dynamic>? data}) {
    debug('📊 BLOC STATE: $blocName - $state', data: data);
  }

  static void flashing(String location, String reason, {Map<String, dynamic>? data}) {
    warning('⚡ FLASHING DETECTED: $location - $reason', data: data);
  }

  static void performance(String operation, Duration duration, {Map<String, dynamic>? data}) {
    debug('⏱️ PERFORMANCE: $operation took ${duration.inMilliseconds}ms', data: data);
  }
}
