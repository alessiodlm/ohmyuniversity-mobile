import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/career_profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/jwt_claims.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<AuthSessionEntity> login({
    required String universityId,
    required String username,
    required String password,
  }) async {
    final session = await _remoteDataSource.login(
      universityId: universityId,
      username: username,
      password: password,
    );
    await _localDataSource.saveSession(session);
    return session;
  }

  @override
  Future<AuthSessionEntity> switchCareer(CareerProfileEntity profile) async {
    final session = await _localDataSource.readSession();
    if (session == null) {
      throw StateError('Sessione non disponibile.');
    }

    final selectedProfile = CareerProfileModel.fromEntity(profile);
    final accessToken = await _remoteDataSource.switchCareer(
      session: session,
      profile: selectedProfile,
    );

    final updatedSession = session.copyWith(accessToken: accessToken);
    await _localDataSource.saveSession(updatedSession);
    return updatedSession;
  }

  @override
  Future<void> logout() async {
    final session = await _localDataSource.readSession();
    try {
      if (session != null) await _remoteDataSource.logout(session);
    } finally {
      await _localDataSource.clearSession();
    }
  }

  @override
  Future<AuthSessionEntity?> currentSession() => _localDataSource.readSession();

  @override
  Future<bool> isAuthenticated() async {
    final session = await _localDataSource.readSession();
    if (session == null ||
        session.accessToken.isEmpty ||
        session.refreshToken.isEmpty ||
        session.universityId.isEmpty) {
      await _localDataSource.clearSession();
      return false;
    }

    final claims = decodeJwtClaims(session.accessToken);
    if (claims == null || !_hasSessionClaims(claims)) {
      await _localDataSource.clearSession();
      return false;
    }

    if (!_isAccessTokenExpired(claims)) return true;

    try {
      final newAccessToken = await _remoteDataSource.refreshAccessToken(
        session,
      );
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _localDataSource.clearSession();
        return false;
      }

      await _localDataSource.saveSession(
        session.copyWith(accessToken: newAccessToken),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isAccessTokenExpired(Map<String, dynamic> claims) {
    final expiration = claims['exp'] as num?;
    if (expiration == null) return true;
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(
      expiration.toInt() * 1000,
    );
    return DateTime.now()
        .add(const Duration(seconds: 30))
        .isAfter(expirationDate);
  }

  bool _hasSessionClaims(Map<String, dynamic> claims) {
    final subject = claims['sub'] as String?;
    final universityId = claims['uni'] as String?;
    return subject != null &&
        subject.trim().isNotEmpty &&
        universityId != null &&
        universityId.trim().isNotEmpty;
  }
}