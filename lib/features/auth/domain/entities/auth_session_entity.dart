import '../../../../core/utils/jwt_claims.dart';
import 'career_profile_entity.dart';

class AuthSessionEntity {
  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.universityId,
    required this.username,
    required this.nome,
    required this.cognome,
    required this.profiles,
  });

  final String accessToken;
  final String refreshToken;
  final String universityId;
  final String username;
  final String nome;
  final String cognome;
  final List<CareerProfileEntity> profiles;

  String get fullName => [
    nome,
    cognome,
  ].where((value) => value.trim().isNotEmpty).join(' ').trim();

  CareerProfileEntity? get activeProfile {
    final claims = decodeJwtClaims(accessToken);
    final stuId = _claimAsInt(claims, 'stuId');
    final matId = _claimAsInt(claims, 'matId');

    if (stuId != null && matId != null) {
      final match = profiles
          .where((p) => p.studentId == stuId && p.enrollmentId == matId)
          .firstOrNull;
      if (match != null) return match;
    }

    return profiles.firstOrNull;
  }

  int? _claimAsInt(Map<String, dynamic>? claims, String key) {
    final value = claims?[key];
    if (value == null) return null;
    return (value as num).toInt();
  }
}