import 'package:flutter_test/flutter_test.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/academic_statistics_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/career_snapshot_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/exam_appeal_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/exam_appeal_month_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/exam_booking_history_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/tuition_fee_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/tuition_snapshot_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/repositories/academic_repository.dart';
import 'package:ohmyuniversity/features/academics/domain/repositories/tuition_repository.dart';
import 'package:ohmyuniversity/features/academics/domain/usecases/get_active_exam_bookings_usecase.dart';
import 'package:ohmyuniversity/features/academics/domain/usecases/get_bookable_exam_sessions_usecase.dart';
import 'package:ohmyuniversity/features/academics/domain/usecases/get_exam_booking_history_usecase.dart';
import 'package:ohmyuniversity/features/academics/domain/usecases/get_tuition_snapshot_usecase.dart';
import 'package:ohmyuniversity/features/academics/domain/usecases/get_visible_exam_appeal_months_usecase.dart';

void main() {
  test('visible appeal months follow academic session ordering', () {
    final result = const GetVisibleExamAppealMonthsUseCase().call(
      currentDate: DateTime(2026, 12, 2),
      appeals: [
        _appeal('feb', DateTime(2027, 2, 10)),
        _appeal('jun', DateTime(2026, 6, 12)),
        _appeal('jan', DateTime(2027, 1, 8)),
        _appeal('old', DateTime(2025, 9, 20)),
        _appeal('mar', DateTime(2027, 3, 4)),
      ],
    );

    expect(
      result,
      const [
        ExamAppealMonthEntity(month: 6, year: 2026),
        ExamAppealMonthEntity(month: 1, year: 2027),
        ExamAppealMonthEntity(month: 2, year: 2027),
      ],
    );
    expect(result.last.id, '2027-2');
  });

  test('visible appeal months hide winter session before december', () {
    final result = const GetVisibleExamAppealMonthsUseCase().call(
      currentDate: DateTime(2026, 10, 20),
      appeals: [
        _appeal('sep', DateTime(2026, 9, 14)),
        _appeal('jan', DateTime(2027, 1, 8)),
      ],
    );

    expect(result, const [ExamAppealMonthEntity(month: 9, year: 2026)]);
  });

  test('bookable/active booking use cases delegate to repository', () async {
    final repository = _AcademicRepositoryFake();
    final bookable = await GetBookableExamSessionsUseCase(repository).call();
    final activeBookings = await GetActiveExamBookingsUseCase(
      repository,
    ).call();
    final history = await GetExamBookingHistoryUseCase(
      repository,
    ).call('secret');
    final cached = await GetExamBookingHistoryUseCase(repository).cached();

    expect(bookable.single['adCod'], 'MAT01');
    expect(activeBookings.single['adsceId'], 10);
    expect(history.single.courseName, 'Analisi');
    expect(cached, isNotNull);
    expect(repository.password, 'secret');
  });

  test('tuition use case delegates to repository', () async {
    final snapshot = await GetTuitionSnapshotUseCase(
      _TuitionRepositoryFake(),
    ).call();

    expect(snapshot.status, 'pending');
    expect(snapshot.totalDue, 450);
    expect(snapshot.academicYearTotal, 570);
    expect(snapshot.paidTotal, 120);
  });
}

ExamAppealEntity _appeal(String id, DateTime date) {
  return ExamAppealEntity(
    id: id,
    examName: 'Analisi',
    month: date.month,
    date: date,
    time: '09:00',
    isBooked: false,
  );
}

const _history = ExamBookingHistoryEntity(
  id: 1,
  activityId: 10,
  courseCode: 'MAT01',
  courseName: 'Analisi',
  bookingDate: null,
  examDate: null,
  credits: 9,
  grade: null,
  passed: false,
  absent: false,
  withdrawn: false,
);

class _AcademicRepositoryFake implements AcademicRepository {
  String? password;

  @override
  Future<List<Map<String, dynamic>>> getBookableExamSessions() async {
    return const [
      {'adCod': 'MAT01', 'adDes': 'Analisi', 'adsceId': 10, 'appId': 1},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveExamBookings() async {
    return const [
      {'adsceId': 10, 'appId': 1, 'adStuCod': 'MAT01'},
    ];
  }

  @override
  Future<List<ExamBookingHistoryEntity>?> getCachedExamBookingHistory() async {
    return [_history.copyWith(courseName: 'Fisica')];
  }

  @override
  Future<CareerSnapshotEntity> getCareerSnapshot() async {
    return const CareerSnapshotEntity(
      courses: [],
      statistics: AcademicStatisticsEntity.empty,
    );
  }

  @override
  Future<List<ExamBookingHistoryEntity>> getExamBookingHistory(
    String password,
  ) async {
    this.password = password;
    return [_history];
  }

  @override
  Future<List<Map<String, dynamic>>> getSuggestedExams() async {
    return const [];
  }
}

class _TuitionRepositoryFake implements TuitionRepository {
  @override
  Future<TuitionSnapshotEntity> getTuitionSnapshot() async {
    return const TuitionSnapshotEntity(
      status: 'pending',
      totalDue: 450,
      fees: [
        TuitionFeeEntity(
          id: 'fee-1',
          title: 'Prima rata',
          amount: 450,
          isPaid: false,
          isOverdue: false,
          receiptAvailable: false,
        ),
        TuitionFeeEntity(
          id: 'fee-2',
          title: 'Ricevuta',
          amount: 120,
          isPaid: true,
          isOverdue: false,
          receiptAvailable: true,
        ),
      ],
    );
  }
}