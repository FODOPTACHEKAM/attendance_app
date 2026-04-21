# Attendance App Project File Explanation

## Root Level Files
| File | Description |
|------|-------------|
| `pubspec.yaml` | Flutter project dependencies and metadata. Defines SDK, packages like provider, go_router, webview_flutter, hotspot plugins.
| `analysis_options.yaml` | Dart analyzer configuration (linter rules).
| `README.md` | Project overview, setup instructions.
| `TODO.md` | Task tracker for ongoing work.
| `TODO_GPS.md` | GPS feature implementation steps.

## lib/main.dart
App entry point. Sets up MultiProvider (AttendanceProvider), MaterialApp.router with go_router, light/dark themes from theme.dart.

## lib/nav.dart
GoRouter configuration (`AppRouter`). Routes:
- `/` HomePage
- `/setup` SessionSetupPage
- `/dashboard` LecturerDashboardPage
- `/register` StudentRegistrationPage

## lib/theme.dart
Custom themes, spacing (`AppSpacing`), radius (`AppRadius`), TextStyle extensions (.bold, .withColor), Color extensions (.withValues(alpha:)). Modern blue-gray palette.

## lib/pages/
UI screens:

| File | Description |
|------|-------------|
| `home_page.dart` | Splash/landing with lecturer/student role cards.
| `session_setup_page.dart` | Session creation (course, timers, max count, hotspot toggle, Excel upload, custom HTML editor).
| `lecturer_dashboard_page.dart` | Real-time dashboard (stats, heatmap, PIN regen, session end/report).
| `student_registration_page.dart` | Glassmorphic student form (matricule, name, PIN) with animations.
| `captive_editor_page.dart` | HTML editor for captive portal (title, course, labels), generates/previews.
| `captive_preview_page.dart` | WebView preview of generated captive HTML.
| `captive.html` | Default static captive portal template (assets).

## lib/models/
Data classes:

| File | Description |
|------|-------------|
| `session.dart` | AttendanceSession (id, course, timers, PIN, GPS radius).
| `attendance_record.dart` | AttendanceRecord (student, join/verify times, device fingerprint).
| `student.dart` | Student (matricule, name, device).
| `user.dart` | User model (unused?).
| `attendance_record.dart` | Duplicate? AttendanceRecord.

## lib/managers/
| File | Description |
|------|-------------|
| `hotspot_manager.dart` | Hotspot state management (unused?).

## lib/services/
Business logic:

| File | Description |
|------|-------------|
| `hotspot_service.dart` | MethodChannel to native hotspot (start/stop, local URL).
| `session_service.dart` | Session CRUD, student registration, PIN gen, connection tracking Timer.
| `storage_service.dart` | SharedPreferences/SQLite for sessions/records/students.
| `device_service.dart` | Device fingerprint/ID.
| `excel_service.dart` | Excel import/export for reports/previous data.

## lib/providers/
| File | Description |
|------|-------------|
| `attendance_provider.dart` | ChangeNotifier for app state (session, records, loading, errors, API calls).

## Platform Folders (android/ios/etc)
Standard Flutter platform code + HotspotService.kt (native Android hotspot/server/captive handler).

App flow: Lecturer → Setup → Hotspot + Captive → Students connect/register → Dashboard → Excel report.
