import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class DeviceInfo {
  final String deviceModel;
  final String osVersion;
  final String browserName;
  final String browserVersion;
  final String userAgent;
  final String platform;
  final String screenResolution;
  final String language;
  final String timeZone;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  DeviceInfo({
    required this.deviceModel,
    required this.osVersion,
    required this.browserName,
    required this.browserVersion,
    required this.userAgent,
    required this.platform,
    required this.screenResolution,
    required this.language,
    required this.timeZone,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'browserName': browserName,
      'browserVersion': browserVersion,
      'userAgent': userAgent,
      'platform': platform,
      'screenResolution': screenResolution,
      'language': language,
      'timeZone': timeZone,
      'isMobile': isMobile,
      'isTablet': isTablet,
      'isDesktop': isDesktop,
    };
  }
}

class DeviceInfoService {
  /// Collect comprehensive device and browser information
  static Future<DeviceInfo> getDeviceInfo() async {
    try {
      final userAgent = html.window.navigator.userAgent;
      final platform = html.window.navigator.platform ?? 'Unknown';
      
      // Parse browser information
      final browserInfo = _parseBrowserInfo(userAgent);
      
      // Parse OS information
      final osInfo = _parseOSInfo(userAgent, platform);
      
      // Device type detection
      final deviceType = _detectDeviceType(userAgent);
      
      // Screen information
      final screen = html.window.screen;
      final screenResolution = screen != null 
          ? '${screen.width}x${screen.height}'
          : 'Unknown';
      
      // Language and timezone
      final language = html.window.navigator.language ?? 'Unknown';
      final timeZone = DateTime.now().timeZoneName;
      
      return DeviceInfo(
        deviceModel: _getDeviceModel(userAgent),
        osVersion: osInfo['version'] ?? 'Unknown',
        browserName: browserInfo['name'] ?? 'Unknown',
        browserVersion: browserInfo['version'] ?? 'Unknown',
        userAgent: userAgent,
        platform: platform,
        screenResolution: screenResolution,
        language: language,
        timeZone: timeZone,
        isMobile: deviceType['isMobile'] ?? false,
        isTablet: deviceType['isTablet'] ?? false,
        isDesktop: deviceType['isDesktop'] ?? true,
      );
    } catch (e) {
      print('❌ Error collecting device info: $e');
      
      // Return basic fallback info
      return DeviceInfo(
        deviceModel: 'Unknown',
        osVersion: 'Unknown',
        browserName: 'Unknown',
        browserVersion: 'Unknown',
        userAgent: html.window.navigator.userAgent,
        platform: html.window.navigator.platform ?? 'Unknown',
        screenResolution: 'Unknown',
        language: html.window.navigator.language ?? 'Unknown',
        timeZone: DateTime.now().timeZoneName,
        isMobile: false,
        isTablet: false,
        isDesktop: true,
      );
    }
  }

  static Map<String, String> _parseBrowserInfo(String userAgent) {
    // Chrome
    if (userAgent.contains('Chrome/')) {
      final chromeMatch = RegExp(r'Chrome/(\d+\.\d+\.\d+\.\d+)').firstMatch(userAgent);
      return {
        'name': 'Chrome',
        'version': chromeMatch?.group(1) ?? 'Unknown'
      };
    }
    
    // Firefox
    if (userAgent.contains('Firefox/')) {
      final firefoxMatch = RegExp(r'Firefox/(\d+\.\d+)').firstMatch(userAgent);
      return {
        'name': 'Firefox',
        'version': firefoxMatch?.group(1) ?? 'Unknown'
      };
    }
    
    // Safari
    if (userAgent.contains('Safari/') && !userAgent.contains('Chrome/')) {
      final safariMatch = RegExp(r'Version/(\d+\.\d+\.\d+)').firstMatch(userAgent);
      return {
        'name': 'Safari',
        'version': safariMatch?.group(1) ?? 'Unknown'
      };
    }
    
    // Edge
    if (userAgent.contains('Edg/')) {
      final edgeMatch = RegExp(r'Edg/(\d+\.\d+\.\d+\.\d+)').firstMatch(userAgent);
      return {
        'name': 'Edge',
        'version': edgeMatch?.group(1) ?? 'Unknown'
      };
    }
    
    return {'name': 'Unknown', 'version': 'Unknown'};
  }

  static Map<String, String> _parseOSInfo(String userAgent, String platform) {
    // Windows
    if (userAgent.contains('Windows NT')) {
      final windowsMatch = RegExp(r'Windows NT (\d+\.\d+)').firstMatch(userAgent);
      final version = windowsMatch?.group(1);
      String windowsVersion = 'Unknown';
      
      switch (version) {
        case '10.0':
          windowsVersion = 'Windows 10/11';
          break;
        case '6.3':
          windowsVersion = 'Windows 8.1';
          break;
        case '6.2':
          windowsVersion = 'Windows 8';
          break;
        case '6.1':
          windowsVersion = 'Windows 7';
          break;
        default:
          windowsVersion = 'Windows $version';
      }
      
      return {'name': 'Windows', 'version': windowsVersion};
    }
    
    // macOS
    if (userAgent.contains('Mac OS X')) {
      final macMatch = RegExp(r'Mac OS X (\d+_\d+_\d+)').firstMatch(userAgent);
      final version = macMatch?.group(1)?.replaceAll('_', '.');
      return {'name': 'macOS', 'version': version ?? 'Unknown'};
    }
    
    // iOS
    if (userAgent.contains('iPhone OS') || userAgent.contains('iPad')) {
      final iosMatch = RegExp(r'OS (\d+_\d+_?\d*)').firstMatch(userAgent);
      final version = iosMatch?.group(1)?.replaceAll('_', '.');
      return {'name': 'iOS', 'version': version ?? 'Unknown'};
    }
    
    // Android
    if (userAgent.contains('Android')) {
      final androidMatch = RegExp(r'Android (\d+\.\d+\.\d+|\d+\.\d+|\d+)').firstMatch(userAgent);
      return {'name': 'Android', 'version': androidMatch?.group(1) ?? 'Unknown'};
    }
    
    // Linux
    if (userAgent.contains('Linux')) {
      return {'name': 'Linux', 'version': 'Unknown'};
    }
    
    return {'name': platform, 'version': 'Unknown'};
  }

  static Map<String, bool> _detectDeviceType(String userAgent) {
    final isMobile = RegExp(r'Mobile|iPhone|iPod|Android|BlackBerry|Opera Mini|IEMobile').hasMatch(userAgent);
    final isTablet = RegExp(r'iPad|Android(?!.*Mobile)|Tablet').hasMatch(userAgent);
    final isDesktop = !isMobile && !isTablet;
    
    return {
      'isMobile': isMobile,
      'isTablet': isTablet,
      'isDesktop': isDesktop,
    };
  }

  static String _getDeviceModel(String userAgent) {
    // iPhone models
    if (userAgent.contains('iPhone')) {
      if (userAgent.contains('iPhone OS 17')) return 'iPhone (iOS 17)';
      if (userAgent.contains('iPhone OS 16')) return 'iPhone (iOS 16)';
      if (userAgent.contains('iPhone OS 15')) return 'iPhone (iOS 15)';
      return 'iPhone';
    }
    
    // iPad models
    if (userAgent.contains('iPad')) {
      return 'iPad';
    }
    
    // Android devices
    if (userAgent.contains('Android')) {
      final androidMatch = RegExp(r'Android[^;]*;\s*([^)]+)').firstMatch(userAgent);
      if (androidMatch != null) {
        return 'Android: ${androidMatch.group(1)}';
      }
      return 'Android Device';
    }
    
    // Desktop
    if (userAgent.contains('Windows')) return 'Windows PC';
    if (userAgent.contains('Macintosh')) return 'Mac';
    if (userAgent.contains('Linux')) return 'Linux PC';
    
    return 'Unknown Device';
  }
}
