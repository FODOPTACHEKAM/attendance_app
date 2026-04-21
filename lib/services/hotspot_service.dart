import 'dart:async';
import 'package:flutter/services.dart';

class HotspotService {
  static const MethodChannel _channel = MethodChannel('hotspot_service');
  static const EventChannel _statusChannel = EventChannel('hotspot_status');

  static Future<String?> startHotspot(String ssid, String password) async {
    try {
      final result = await _channel.invokeMethod('startHotspot', {'ssid': ssid, 'password': password});
      return result;
    } on PlatformException catch (e) {
      return Future.error('Failed to start hotspot: ${e.message}');
    }
  }

  static Future<String?> stopHotspot() async {
    try {
      final result = await _channel.invokeMethod('stopHotspot');
      return result;
    } on PlatformException catch (e) {
      return Future.error('Failed to stop hotspot: ${e.message}');
    }
  }

  static Future<String?> getStatus() async {
    try {
      final status = await _channel.invokeMethod('getStatus');
      return status;
    } on PlatformException catch (e) {
      return Future.error('Failed to get status: ${e.message}');
    }
  }

  static Future<String?> getLocalServerUrl() async {
    try {
      final url = await _channel.invokeMethod('getLocalServerUrl');
      return url ?? 'http://192.168.43.1:8080';
    } on PlatformException {
      return 'http://192.168.43.1:8080';
    }
  }

  // Stream for hotspot status changes
  static Stream<String> get statusStream {
    return _statusChannel.receiveBroadcastStream().map((event) => event as String);
  }
}
