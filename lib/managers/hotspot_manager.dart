import '../services/hotspot_service.dart';

enum HotspotStatus { off, turningOn, on, turningOff, error }

class HotspotManager {
  static HotspotStatus _status = HotspotStatus.off;
  static String _ssid = '';
  static String _password = '';
  static String? _portalUrl;

  static HotspotStatus get status => _status;
  static String get ssid => _ssid;
  static String get password => _password;
  static String? get portalUrl => _portalUrl;

  static Future<bool> startHotspot(String ssid, String password) async {
    _status = HotspotStatus.turningOn;
    _ssid = ssid;
    _password = password;
    final result = await HotspotService.startHotspot(ssid, password);
    if (result != null) {
      _portalUrl = await HotspotService.getLocalServerUrl();
      _status = HotspotStatus.on;
      return true;
    }
    _status = HotspotStatus.error;
    return false;
  }

  static Future<bool> stopHotspot() async {
    _status = HotspotStatus.turningOff;
    final result = await HotspotService.stopHotspot();
    if (result != null) {
      _status = HotspotStatus.off;
      return true;
    }
    return false;
  }

  static Future<String?> getStatus() async {
    return await HotspotService.getStatus();
  }

  static Future<String?> getLocalServerUrl() async {
    return await HotspotService.getLocalServerUrl();
  }
}
