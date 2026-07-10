import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/career_profile_entity.dart';

class AuthSessionModel extends AuthSessionEntity {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required super.universityId,
    required super.username,
    required super.nome,
    required super.cognome,
    required super.profiles,
  });

  factory AuthSessionModel.fromJson(
    Map<String, dynamic> json, {
    required String universityId,
    required String username,
  }) {
    final rawProfiles = json['profili'] as List<dynamic>? ?? const [];

    return AuthSessionModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      universityId: universityId,
      username: username,
      nome: json['nome'] as String? ?? '',
      cognome: json['cognome'] as String? ?? '',
      profiles: rawProfiles
          .whereType<Map<String, dynamic>>()
          .map(CareerProfileModel.fromJson)
          .toList(growable: false),
    );
  }

  factory AuthSessionModel.fromStoredJson(Map<String, dynamic> json) {
    return AuthSessionModel.fromJson(
      json,
      universityId: json['universityId'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }

  AuthSessionModel copyWith({
    String? accessToken,
    String? refreshToken,
    String? universityId,
    String? username,
    String? nome,
    String? cognome,
    List<CareerProfileEntity>? profiles,
  }) {
    return AuthSessionModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      universityId: universityId ?? this.universityId,
      username: username ?? this.username,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      profiles: profiles ?? this.profiles,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'universityId': universityId,
    'username': username,
    'nome': nome,
    'cognome': cognome,
    'profili': profiles
        .map((profile) => CareerProfileModel.fromEntity(profile).toJson())
        .toList(growable: false),
  };
}

class CareerProfileModel extends CareerProfileEntity {
  const CareerProfileModel({
    required super.universityId,
    required super.universityName,
    required super.studentId,
    required super.enrollmentId,
    required super.studentNumber,
    required super.courseName,
    required super.courseCode,
    required super.degreeCourseId,
    required super.courseTypeCode,
    required super.studentStatus,
    required super.studentStatusDescription,
    required super.courseYear,
    required super.courseDurationYears,
    required super.academicYear,
    required super.active,
    required super.graduated,
  });

  factory CareerProfileModel.fromJson(Map<String, dynamic> json) {
    return CareerProfileModel(
      universityId: json['universityId'] as String? ?? '',
      universityName: json['universityName'] as String? ?? '',
      studentId: (json['stuId'] as num?)?.toInt(),
      enrollmentId: (json['matId'] as num?)?.toInt(),
      studentNumber: json['matricola'] as String? ?? '',
      courseName: json['corsoNome'] as String? ?? '',
      courseCode: json['corsoCodice'] as String? ?? '',
      degreeCourseId: (json['cdsId'] as num?)?.toInt(),
      courseTypeCode: json['tipoCorsoCod'] as String? ?? '',
      studentStatus: json['statusStudente'] as String? ?? '',
      studentStatusDescription: json['statusDescrizione'] as String? ?? '',
      courseYear: (json['annoCorso'] as num?)?.toInt(),
      courseDurationYears: (json['durataAnni'] as num?)?.toInt(),
      academicYear: (json['annoAccademico'] as num?)?.toInt(),
      active: json['attivo'] as bool? ?? false,
      graduated: json['laureato'] as bool? ?? false,
    );
  }

  factory CareerProfileModel.fromEntity(CareerProfileEntity entity) {
    return CareerProfileModel(
      universityId: entity.universityId,
      universityName: entity.universityName,
      studentId: entity.studentId,
      enrollmentId: entity.enrollmentId,
      studentNumber: entity.studentNumber,
      courseName: entity.courseName,
      courseCode: entity.courseCode,
      degreeCourseId: entity.degreeCourseId,
      courseTypeCode: entity.courseTypeCode,
      studentStatus: entity.studentStatus,
      studentStatusDescription: entity.studentStatusDescription,
      courseYear: entity.courseYear,
      courseDurationYears: entity.courseDurationYears,
      academicYear: entity.academicYear,
      active: entity.active,
      graduated: entity.graduated,
    );
  }

  CareerProfileModel copyWith({
    String? universityId,
    String? universityName,
    int? studentId,
    int? enrollmentId,
    String? studentNumber,
    String? courseName,
    String? courseCode,
    int? degreeCourseId,
    String? courseTypeCode,
    String? studentStatus,
    String? studentStatusDescription,
    int? courseYear,
    int? courseDurationYears,
    int? academicYear,
    bool? active,
    bool? graduated,
  }) {
    return CareerProfileModel(
      universityId: universityId ?? this.universityId,
      universityName: universityName ?? this.universityName,
      studentId: studentId ?? this.studentId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      studentNumber: studentNumber ?? this.studentNumber,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      degreeCourseId: degreeCourseId ?? this.degreeCourseId,
      courseTypeCode: courseTypeCode ?? this.courseTypeCode,
      studentStatus: studentStatus ?? this.studentStatus,
      studentStatusDescription:
          studentStatusDescription ?? this.studentStatusDescription,
      courseYear: courseYear ?? this.courseYear,
      courseDurationYears: courseDurationYears ?? this.courseDurationYears,
      academicYear: academicYear ?? this.academicYear,
      active: active ?? this.active,
      graduated: graduated ?? this.graduated,
    );
  }

  Map<String, dynamic> toJson() => {
    'universityId': universityId,
    'universityName': universityName,
    'stuId': studentId,
    'matId': enrollmentId,
    'matricola': studentNumber,
    'corsoNome': courseName,
    'corsoCodice': courseCode,
    'cdsId': degreeCourseId,
    'tipoCorsoCod': courseTypeCode,
    'statusStudente': studentStatus,
    'statusDescrizione': studentStatusDescription,
    'annoCorso': courseYear,
    'durataAnni': courseDurationYears,
    'annoAccademico': academicYear,
    'attivo': active,
    'laureato': graduated,
  };
}