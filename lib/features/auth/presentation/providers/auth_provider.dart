import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers/network_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/career_profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/switch_career_usecase.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiDioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final switchCareerUseCaseProvider = Provider<SwitchCareerUseCase>((ref) {
  return SwitchCareerUseCase(ref.watch(authRepositoryProvider));
});

final isAuthenticatedProvider = NotifierProvider<IsAuthenticated, bool>(
  IsAuthenticated.new,
);

class IsAuthenticated extends Notifier<bool> {
  @override
  bool build() => false;

  void setAuthenticated(bool value) => state = value;

  Future<bool> restore() async {
    final authenticated = await ref
        .read(authRepositoryProvider)
        .isAuthenticated();
    state = authenticated;
    return authenticated;
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSessionEntity?>(
      AuthSessionNotifier.new,
    );

class AuthSessionNotifier extends AsyncNotifier<AuthSessionEntity?> {
  @override
  Future<AuthSessionEntity?> build() {
    return ref.read(authRepositoryProvider).currentSession();
  }

  Future<void> switchCareer(CareerProfileEntity profile) async {
    final updated = await ref.read(switchCareerUseCaseProvider).call(profile);
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    state = AsyncData(
      await ref.read(authRepositoryProvider).currentSession(),
    );
  }
}