# Hotspot Feature Explanation

The hotspot feature enables lecturers to create a WiFi hotspot with captive portal for attendance. Flow: Setup → Start hotspot → Students connect/register → Verify.

## Key Files:

### 1. lib/services/hotspot_service.dart (Dart Platform Channel)
```dart
class HotspotService {
  static const MethodChannel _channel = MethodChannel('hotspot_service');
  
  static Future<String?> startHotspot(String ssid, String password) => _channel.invokeMethod('startHotspot', {'ssid': ssid, 'password': password});
  static Future<String?> stopHotspot() => _channel.invokeMethod('stopHotspot');
  static Future<String?> getLocalServerUrl() => _channel.invokeMethod('getLocalServerUrl') ?? 'http://192.168.43.1:8080';
}
```
**Role**: Calls native Android hotspot via MethodChannel. Returns local server URL for captive portal.

### 2. android/app/src/main/kotlin/.../HotspotService.kt (Native Android)
**Role**: 
- Creates WiFi hotspot (SSID/pass via reflection/TetheringManager).
- Starts HTTP server on port 8080 (captive portal).
- Handles /register POST (saves student data to JSON).
- Serves captive.html at root.
- Captures device IP/MAC for verification.

**Key Methods**:
- `enableHotspot(ssid, pass)`: Reflection + TetheringManager fallback.
- `HttpHandler`: Parses POST, saves registrations, serves HTML.
- Notification foreground service.

### 3. lib/pages/session_setup_page.dart (UI Control)
**Role**: Lecturer UI to start/stop hotspot, edit captive HTML.
```dart
Future<void> _toggleHotspot() async {
  if (_hotspotActive) await HotspotService.stopHotspot();
  else {
    await HotspotService.startHotspot(ssid, pass);
    _hotspotUrl = await HotspotService.getLocalServerUrl();
  }
}
```
Buttons: "Start/Stop Hotspot Portal", "Edit Captive HTML", "View Captive Page".

### 4. lib/pages/captive_editor_page.dart + captive_preview_page.dart
**Role**: Custom captive HTML generator/editor + WebView preview. JS GPS capture added.

### 5. lib/managers/hotspot_manager.dart (State - partial)
Potential state manager (not fully used).

### Flow:
1. Lecturer: SessionSetupPage → startHotspot() → native service.
2. Native: Hotspot ON + server/captive.html at 192.168.43.1:8080.
3. Student connects → captive portal → register (name/email/matricule/GPS) → POST /register → saved.
4. Flutter: Polls storage → dashboard shows verified students.

**Web Limitation**: MethodChannel not supported on web (hotspot plugin Android-only). Test on physical Android device.

**Extension**: Add student verification using saved IP/MAC from hotspot handler.
