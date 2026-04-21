import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_record.dart';

class CaptiveStorageService {
  static const String _registrationsFile = 'captive_registrations.json';

  /// Save student registration from captive portal
  static Future<bool> saveRegistration({
    required String sessionId,
    required String fullName,
    required String email,
    required String matricule,
    String deviceFingerprint = '',
    double? latitude,
    double? longitude,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_registrationsFile');
      
      List<dynamic> registrations = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        registrations = json.decode(content);
      }

      registrations.add({
        'sessionId': sessionId,
        'fullName': fullName,
        'email': email,
        'matricule': matricule,
        'deviceFingerprint': deviceFingerprint,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'verified': false,
      });

      await file.writeAsString(json.encode(registrations));
      return true;
    } catch (e) {
      print('Save error: $e');
      return false;
    }
  }

  /// Get unverified registrations for session
  static Future<List<Map<String, dynamic>>> getUnverifiedRegistrations(String sessionId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_registrationsFile');
      
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final List<dynamic> allRegs = json.decode(content);
      
      return allRegs
        .cast<Map<String, dynamic>>()
        .where((reg) => reg['sessionId'] == sessionId && !reg['verified'])
        .toList();
    } catch (e) {
      print('Load error: $e');
      return [];
    }
  }

  /// Mark registration as verified
  static Future<bool> markAsVerified(String sessionId, String matricule) async {
    try {
      final regs = await getUnverifiedRegistrations(sessionId);
      final index = regs.indexWhere((reg) => reg['matricule'] == matricule);
      if (index != -1) {
        regs[index]['verified'] = true;
        // Save back all
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_registrationsFile');
        await file.writeAsString(json.encode(regs));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Export to CSV
  static Future<String?> exportToCsv(String sessionId) async {
    try {
      final regs = await getUnverifiedRegistrations(sessionId);
      final verifiedRegs = regs.where((r) => r['verified']).toList();
      
      final dir = await getApplicationDocumentsDirectory();
      final csvFile = File('${dir.path}/attendance_${sessionId}.csv');
      
      final headers = 'Matricule,Full Name,Email,Verified,Latitude,Longitude,Timestamp\\n';
      final rows = verifiedRegs.map((reg) => 
        '${reg['matricule']},${reg['fullName']},${reg['email']},${reg['verified']},${reg['latitude'] ?? ''},${reg['longitude'] ?? ''},${reg['timestamp']}'
      ).join('\\n');
      
      await csvFile.writeAsString(headers + rows);
      return csvFile.path;
    } catch (e) {
      return null;
    }
  }
}

