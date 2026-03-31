import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/attendance_record.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../services/excel_service.dart';

/// Provider for attendance system state management
class AttendanceProvider extends ChangeNotifier {
  final SessionService _sessionService = SessionService();
  final StorageService _storage = StorageService();
  final ExcelService _excelService = ExcelService();

  AttendanceSession? _activeSession;
  List<AttendanceRecord> _currentRecords = [];
  Map<String, int> _previousAttendance = {};
  bool _isLoading = false;
  String? _error;

  AttendanceSession? get activeSession => _activeSession;
  List<AttendanceRecord> get currentRecords => _currentRecords;
  Map<String, int> get previousAttendance => _previousAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeSession = await _storage.getActiveSession();
      if (_activeSession != null) {
        await refreshRecords();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new session
  Future<void> createSession({
    required String courseName,
    required int gracePeriodMinutes,
    required int requiredConnectionMinutes,
    required int maxAttendanceCount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeSession = await _sessionService.createSession(
        courseName: courseName,
        lecturerId: 'lecturer_1', // In a real app, get from auth
        gracePeriodMinutes: gracePeriodMinutes,
        requiredConnectionMinutes: requiredConnectionMinutes,
        maxAttendanceCount: maxAttendanceCount,
      );
      _currentRecords = [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Upload previous session data
  Future<bool> uploadPreviousSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _excelService.uploadPreviousSession();
      if (data != null) {
        _previousAttendance = {
          for (var student in data) student.matricule: student.totalPresence
        };
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Failed to load previous session data';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a student
  Future<bool> registerStudent({
    required String matricule,
    required String studentName,
    required String pin,
  }) async {
    try {
      await _sessionService.registerStudent(
        matricule: matricule,
        studentName: studentName,
        pin: pin,
      );
      await refreshRecords();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Regenerate PIN
  Future<String?> regeneratePin() async {
    try {
      final newPin = await _sessionService.regeneratePin();
      if (newPin != null && _activeSession != null) {
        _activeSession = _activeSession!.copyWith(currentPin: newPin);
        _error = null;
        notifyListeners();
      }
      return newPin;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Refresh attendance records
  Future<void> refreshRecords() async {
    if (_activeSession == null) return;

    try {
      _currentRecords =
          await _storage.getAttendanceRecords(_activeSession!.id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// End session and generate report
  Future<String?> endSessionAndGenerateReport() async {
    if (_activeSession == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final filePath = await _excelService.generateReport(
        courseName: _activeSession!.courseName,
        sessionDate: _activeSession!.startTime,
        currentSessionRecords: _currentRecords,
        previousAttendance: _previousAttendance,
        maxAttendanceCount: _activeSession!.maxAttendanceCount,
      );

      await _sessionService.endSession(_activeSession!.id);
      _activeSession = null;
      _currentRecords = [];
      _error = null;

      _isLoading = false;
      notifyListeners();

      return filePath;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get session statistics
  Map<String, int> getStats() {
    final verified = _currentRecords
        .where((r) => r.isVerified && r.isPinVerified)
        .length;
    final pending = _currentRecords
        .where((r) => !r.isVerified || !r.isPinVerified)
        .length;

    return {
      'total': _currentRecords.length,
      'verified': verified,
      'pending': pending,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
