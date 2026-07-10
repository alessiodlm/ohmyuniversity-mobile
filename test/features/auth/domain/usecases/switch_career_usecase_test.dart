import 'package:flutter_test/flutter_test.dart';
import 'package:ohmyuniversity/features/auth/domain/entities/auth_session_entity.dart';
import 'package:ohmyuniversity/features/auth/domain/entities/career_profile_entity.dart';
import 'package:ohmyuniversity/features/auth/domain/repositories/auth_repository.dart';
import 'package:ohmyuniversity/features/auth/domain/usecases/switch_career_usecase.dart';

void main() {
  test('switch career delegates selected profile to repository', () async {
    final repository = _FakeAuthRepository();
    final useCase = SwitchCareerUseCase(repository);
    final session = await useCase(_profile);
    expect(repository.lastProfile, same(_profile));
    expect(session.activeProfile, same(_profile));
  });
}

class _FakeAuthRepository implements AuthRepository {
  CareerProfileEntity? lastProfile;

  @override
  Future<AuthSessionEntity> switchCareer(CareerProfileEntity profile) async {
    lastProfile = profile;
    return AuthSessionEntity(
      accessToken: 'access',
      refreshToken: 'refresh',
      universityId: profile.universityId,
      username: 'student',
      nome: 'Mario',
      cognome: 'Rossi',
      profiles: [profile],
    );
  }

  @override
  Future<AuthSessionEntity?> currentSession() async => null;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<AuthSessionEntity> login({
    required String universityId,
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

const _profile = CareerProfileEntity(
  universityId: 'UNIMOL',
  universityName: 'Universita degli Studi del Molise',
  studentId: 1,
  enrollmentId: 2,
  studentNumber: '12345',
  courseName: 'Informatica',
  courseCode: 'INF',
  degreeCourseId: 3,
  courseTypeCode: 'L',
  studentStatus: 'A',
  studentStatusDescription: 'Attivo',
  courseYear: 2,
  courseDurationYears: 3,
  academicYear: 2026,
  active: true,
  graduated: false,
);