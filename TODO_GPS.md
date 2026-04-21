# GPS Location for Captive Portal TODO

## Steps:
- [x] Step 1: Edit lib/pages/captive_editor_page.dart (add JS GPS capture to HTML)
- [x] Step 2: Edit lib/pages/session_setup_page.dart (add GPS radius field)
- [x] Step 3: Edit lib/models/session.dart (add radiusKm)
- [x] Update lib/services/session_service.dart
- [ ] Step 4: Edit android/app/src/main/kotlin/.../HotspotService.kt (parse GPS lat/lng)
- [ ] Step 5: Edit lib/models/attendance_record.dart (add latitude, longitude)
- [ ] Step 6: Edit providers/attendance_provider.dart & services (store GPS, radius validation)
- [ ] Step 7: Edit lib/pages/lecturer_dashboard_page.dart (display GPS/map?)
- [ ] Step 8: Run flutter analyze & test

GPS captured on portal submit, validated vs session radius.

