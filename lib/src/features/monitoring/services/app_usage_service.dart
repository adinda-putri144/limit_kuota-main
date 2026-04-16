import 'package:flutter/services.dart';

class AppUsageService {
  static const MethodChannel _channel =
      MethodChannel('app.usage.stats');

  static Future<List<dynamic>> getUsage() async {
    final data = await _channel.invokeMethod('getAppUsage');
    return data;
  }
}