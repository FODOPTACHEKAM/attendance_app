/// Attendance record tracking student presence in a session
class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String matricule;
  final String studentName;
  final DateTime joinedAt;
  final DateTime? verifiedAt;
  final int connectionDurationMinutes;
  final bool isVerified;
  final bool isPinVerified;
  final String deviceFingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.matricule,
    required this.studentName,
    required this.joinedAt,
    this.verifiedAt,
    required this.connectionDurationMinutes,
    required this.isVerified,
    required this.isPinVerified,
    required this.deviceFingerprint,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'studentId': studentId,
        'matricule': matricule,
        'studentName': studentName,
        'joinedAt': joinedAt.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'connectionDurationMinutes': connectionDurationMinutes,
        'isVerified': isVerified,
        'isPinVerified': isPinVerified,
        'deviceFingerprint': deviceFingerprint,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        studentId: json['studentId'] as String,
        matricule: json['matricule'] as String,
        studentName: json['studentName'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.parse(json['verifiedAt'] as String)
            : null,
        connectionDurationMinutes: json['connectionDurationMinutes'] as int,
        isVerified: json['isVerified'] as bool,
        isPinVerified: json['isPinVerified'] as bool,
        deviceFingerprint: json['deviceFingerprint'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? matricule,
    String? studentName,
    DateTime? joinedAt,
    DateTime? verifiedAt,
    int? connectionDurationMinutes,
    bool? isVerified,
    bool? isPinVerified,
    String? deviceFingerprint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AttendanceRecord(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        studentId: studentId ?? this.studentId,
        matricule: matricule ?? this.matricule,
        studentName: studentName ?? this.studentName,
        joinedAt: joinedAt ?? this.joinedAt,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        connectionDurationMinutes:
            connectionDurationMinutes ?? this.connectionDurationMinutes,
        isVerified: isVerified ?? this.isVerified,
        isPinVerified: isPinVerified ?? this.isPinVerified,
        deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
