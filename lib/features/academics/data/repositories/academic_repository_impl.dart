import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/career_snapshot_entity.dart';
import '../../domain/entities/academic_exam_course_entity.dart';
import '../../domain/entities/academic_statistics_entity.dart';
import '../../domain/entities/exam_booking_history_entity.dart';
import '../../domain/exceptions/career_data_exception.dart';
import '../../domain/repositories/academic_repository.dart';
import '../../domain/services/academic_statistics_calculator.dart';
import '../datasources/academic_remote_datasource.dart';

class AcademicRepositoryImpl implements AcademicRepository {
  const AcademicRepositoryImpl(
    this._dataSource,
    this._storage, [
    this._calculator = const AcademicStatisticsCalculator(),
  ]);

  static const bookingHistoryCacheKey = 'exam_booking_history';
  final AcademicRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;
  final AcademicStatisticsCalculator _calculator;

  @override
  Future<CareerSnapshotEntity> getCareerSnapshot() async {
    final apiData = await _dataSource.getCareerData();
    final courses = apiData.studyPlan.mergeTranscript(
      apiData.transcript.courses,
    );
    final derived = _calculator.calculate(courses);
    final metrics = apiData.metrics;

    return CareerSnapshotEntity(
      courses: courses,
      statistics: AcademicStatisticsEntity(
        arithmeticAverage:
            metrics.arithmeticAverage ?? derived.arithmeticAverage,
        weightedAverage: metrics.weightedAverage ?? derived.weightedAverage,
        acquiredCredits: metrics.acquiredCredits ?? derived.acquiredCredits,
        totalCredits: metrics.totalCredits ?? derived.totalCredits,
        graduationBase: metrics.graduationBase ?? derived.graduationBase,
        projectedGraduationScore:
            metrics.graduationBase ?? derived.projectedGraduationScore,
        honorsCount: derived.honorsCount,
        gradeHistory: derived.gradeHistory,
        averageTrend: derived.averageTrend,
        hasSimulation: false,
      ),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getSuggestedExams() {
    return _dataSource.getSuggestedExams();
  }

  @override
  Future<List<Map<String, dynamic>>> getBookableExamSessions() {
    return _dataSource.getBookableExamSessions();
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveExamBookings() {
    return _dataSource.getActiveExamBookings();
  }

  @override
  Future<List<ExamBookingHistoryEntity>> getExamBookingHistory(
    String password,
  ) async {
    final bookings = await _enrichBookingHistory(
      await _dataSource.getExamBookingHistory(password),
    );
    await _storage.write(
      key: bookingHistoryCacheKey,
      value: jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'bookings': bookings.map(_bookingToJson).toList(growable: false),
      }),
    );
    return bookings;
  }

  @override
  Future<List<ExamBookingHistoryEntity>?> getCachedExamBookingHistory() async {
    try {
      final value = await _storage.read(key: bookingHistoryCacheKey);
      if (value == null || value.isEmpty) return null;
      final json = jsonDecode(value) as Map<String, dynamic>;
      final bookings = json['bookings'] as List<dynamic>? ?? [];
      final decodedBookings = bookings
          .whereType<Map<String, dynamic>>()
          .map(_bookingFromJson)
          .toList(growable: false);
      return _enrichBookingHistory(decodedBookings);
    } on FormatException {
      await _storage.delete(key: bookingHistoryCacheKey);
      return null;
    } on PlatformException {
      return null;
    }
  }

  Map<String, dynamic> _bookingToJson(ExamBookingHistoryEntity booking) => {
    'id': booking.id,
    'activityId': booking.activityId,
    'enrollmentActivityId': booking.enrollmentActivityId,
    'courseCode': booking.courseCode,
    'courseName': booking.courseName,
    'bookingDate': booking.bookingDate?.toIso8601String(),
    'examDate': booking.examDate?.toIso8601String(),
    'credits': booking.credits,
    'grade': booking.grade,
    'passed': booking.passed,
    'absent': booking.absent,
    'withdrawn': booking.withdrawn,
  };

  ExamBookingHistoryEntity _bookingFromJson(Map<String, dynamic> json) {
    return ExamBookingHistoryEntity(
      id: (json['id'] as num).toInt(),
      activityId: (json['activityId'] as num?)?.toInt(),
      enrollmentActivityId: (json['enrollmentActivityId'] as num?)?.toInt(),
      courseCode: json['courseCode'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      bookingDate: DateTime.tryParse(json['bookingDate'] as String? ?? ''),
      examDate: DateTime.tryParse(json['examDate'] as String? ?? ''),
      credits: (json['credits'] as num?)?.toDouble() ?? 0,
      grade: (json['grade'] as num?)?.toInt(),
      passed: json['passed'] as bool? ?? false,
      absent: json['absent'] as bool? ?? false,
      withdrawn: json['withdrawn'] as bool? ?? false,
    );
  }

  Future<List<ExamBookingHistoryEntity>> _enrichBookingHistory(
    List<ExamBookingHistoryEntity> bookings,
  ) async {
    final needsEnrichment = bookings.any(
      (booking) => booking.courseName.trim().isEmpty || booking.credits <= 0,
    );
    if (!needsEnrichment) return bookings;

    try {
      final apiData = await _dataSource.getCareerData();
      final courses = apiData.studyPlan.mergeTranscript(
        apiData.transcript.courses,
      );
      final coursesById = <int, AcademicExamCourseEntity>{};
      for (final course in courses) {
        final id = int.tryParse(course.id);
        if (id != null) coursesById[id] = course;
      }
      final coursesByCode = {
        for (final course in courses)
          if (course.code.trim().isNotEmpty)
            course.code.trim().toUpperCase(): course,
      };

      return bookings
          .map((booking) {
            final course =
                coursesById[booking.enrollmentActivityId] ??
                coursesByCode[booking.courseCode.trim().toUpperCase()];
            if (course == null) return booking;
            return booking.copyWith(
              courseName: booking.courseName.trim().isEmpty
                  ? course.name
                  : booking.courseName,
              credits: booking.credits <= 0
                  ? course.credits.toDouble()
                  : booking.credits,
            );
          })
          .toList(growable: false);
    } on CareerDataException {
      return bookings;
    }
  }
}