import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.expensetracker.expense_tracker/security');

  static Future<void> enableScreenshotProtection() async {
    try {
      await _channel.invokeMethod('enableScreenshotProtection');
    } catch (e) {
      // Handle error silently - not all platforms support this
    }
  }

  static Future<void> disableScreenshotProtection() async {
    try {
      await _channel.invokeMethod('disableScreenshotProtection');
    } catch (e) {
      // Handle error silently - not all platforms support this
    }
  }
}