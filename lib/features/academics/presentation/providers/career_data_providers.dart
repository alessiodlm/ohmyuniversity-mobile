import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers/network_providers.dart';
import '../../data/datasources/academic_remote_datasource.dart';
import '../../data/repositories/academic_repository_impl.dart';
import '../../domain/entities/career_snapshot_entity.dart';
import '../../domain/repositories/academic_repository.dart';
import '../../domain/usecases/get_active_exam_bookings_usecase.dart';
import '../../domain/usecases/get_bookable_exam_sessions_usecase.dart';
import '../../domain/usecases/get_career_snapshot_usecase.dart';
import '../../domain/usecases/get_exam_booking_history_usecase.dart';

final academicRemoteDataSourceProvider = Provider<AcademicRemoteDataSource>((
  ref,
) {
  return AcademicRemoteDataSource(ref.watch(apiDioProvider));
});

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepositoryImpl(
    ref.watch(academicRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
  );
});

final getCareerSnapshotUseCaseProvider = Provider<GetCareerSnapshotUseCase>((
  ref,
) {
  return GetCareerSnapshotUseCase(ref.watch(academicRepositoryProvider));
});

final getExamBookingHistoryUseCaseProvider =
    Provider<GetExamBookingHistoryUseCase>((ref) {
      return GetExamBookingHistoryUseCase(
        ref.watch(academicRepositoryProvider),
      );
    });

final getBookableExamSessionsUseCaseProvider =
    Provider<GetBookableExamSessionsUseCase>((ref) {
      return GetBookableExamSessionsUseCase(
        ref.watch(academicRepositoryProvider),
      );
    });

final getActiveExamBookingsUseCaseProvider =
    Provider<GetActiveExamBookingsUseCase>((ref) {
      return GetActiveExamBookingsUseCase(
        ref.watch(academicRepositoryProvider),
      );
    });

final careerSnapshotProvider = FutureProvider<CareerSnapshotEntity>((ref) {
  return ref.watch(getCareerSnapshotUseCaseProvider).call();
});