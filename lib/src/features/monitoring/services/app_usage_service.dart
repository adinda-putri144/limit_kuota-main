import 'package:flutter/services.dart';

class AppUsageService {
  static const MethodChannel _channel =
      MethodChannel('limit_kuota/channel'); // WAJIB sama dengan Kotlin

  static Future<List<dynamic>> getUsage() async {
    final data = await _channel.invokeMethod('getAppUsage');
    return data;
  }

  static Future<Map<dynamic, dynamic>> getTodayUsage() async {
    final data = await _channel.invokeMethod('getTodayUsage');
    return data;
  }
}