import '../../domain/entities/career_profile_entity.dart';
import '../../../../shared/widgets/avatar_profile_panel/avatar_profile_panel_widget.dart';

String careerAccountId(CareerProfileEntity profile) =>
    '${profile.studentId}_${profile.enrollmentId}_${profile.studentNumber}';

CareerProfileEntity? findCareerProfileById(
  List<CareerProfileEntity> profiles,
  String id,
) {
  for (final profile in profiles) {
    if (careerAccountId(profile) == id) return profile;
  }
  return null;
}

AccountStatus _statusFor(CareerProfileEntity profile) {
  final code = profile.studentStatus.trim().toUpperCase();  // rinuncia// rinuncia
  return switch (code) {
    'RN' => AccountStatus.withdrawn,
    'TR' => AccountStatus.withdrawn,
    'LA' => AccountStatus.graduated,
    'SO' => AccountStatus.suspended,
    'FC' => AccountStatus.warning,
    _ => AccountStatus.active,
  };
}

String _acronymFor(String courseTypeCode) {
  final code = courseTypeCode.trim().toUpperCase();
  return switch (code) {
    'L' => 'L',
    'LM' => 'LM',
    'LMCU' => 'LMcu',
    'DOTTORATO' || 'PHD' => 'DOT',
    'MASTER1' || 'MASTER2' => 'MASTER',
    _ => code.isEmpty ? 'AM' : code,
  };
}

AccountEntry mapCareerProfileToAccountEntry(
  CareerProfileEntity profile, {
  required String fullName,
  required String email,
  String? avatarSrc,
}) {
  return AccountEntry(
    id: careerAccountId(profile),
    name: fullName,
    courseLabel: profile.courseName,
    email: email,
    universityLabel: profile.universityName,
    courseAcronym: _acronymFor(profile.courseTypeCode),
    avatarSrc: avatarSrc,
    status: _statusFor(profile),
    isCurrent: profile.active,
  );
}