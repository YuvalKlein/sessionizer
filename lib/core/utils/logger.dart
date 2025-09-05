import 'package:flutter/foundation.dart';

class AppLogger {
  // Disable logger in debug mode to avoid DebugService issues
  static const bool _enableLogging = false;

  static void debug(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (_enableLogging && !kReleaseMode) {
      print('DEBUG: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void debugNamed(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (_enableLogging && !kReleaseMode) {
      print('DEBUG: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (_enableLogging && !kReleaseMode) {
      print('INFO: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void infoNamed(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (_enableLogging && !kReleaseMode) {
      print('INFO: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (_enableLogging && !kReleaseMode) {
      print('WARNING: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void warningNamed(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (_enableLogging && !kReleaseMode) {
      print('WARNING: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (_enableLogging && !kReleaseMode) {
      print('ERROR: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data]) {
    if (_enableLogging && !kReleaseMode) {
      print('FATAL: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  // Specific logging methods for debugging flashing issues
  static void widgetBuild(String widgetName, {Map<String, dynamic>? data}) {
    debugNamed('🔨 WIDGET BUILD: $widgetName', data: data);
  }

  static void stateChange(String blocName, String event, {Map<String, dynamic>? data}) {
    debugNamed('🔄 STATE CHANGE: $blocName - $event', data: data);
  }

  static void navigation(String from, String to, {Map<String, dynamic>? data}) {
    debugNamed('🧭 NAVIGATION: $from -> $to', data: data);
  }

  static void blocEvent(String blocName, String event, {Map<String, dynamic>? data}) {
    debugNamed('📡 BLOC EVENT: $blocName - $event', data: data);
  }

  static void blocState(String blocName, String state, {Map<String, dynamic>? data}) {
    debugNamed('📊 BLOC STATE: $blocName - $state', data: data);
  }

  static void flashing(String location, String reason, {Map<String, dynamic>? data}) {
    warningNamed('⚡ FLASHING DETECTED: $location - $reason', data: data);
  }

  static void performance(String operation, Duration duration, {Map<String, dynamic>? data}) {
    debugNamed('⏱️ PERFORMANCE: $operation took ${duration.inMilliseconds}ms', data: data);
  }
}
