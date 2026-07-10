import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/academic_exam_course_entity.dart';
import '../../domain/entities/exam_booking_entity.dart';
import 'career_data_providers.dart';
import 'career_provider.dart';

enum AppealsFilter { all, booked, available, recommended }

class RecommendedExamBooking {
  const RecommendedExamBooking({required this.course, required this.appeal});

  final AcademicExamCourseEntity course;
  final ExamBookingEntity? appeal;
}

class AppealsState {
  const AppealsState({
    this.searchQuery = '',
    this.filter = AppealsFilter.all,
    this.bookedIds = const {},
    this.examBookings = const [],
    this.isLoading = false,
    this.loaded = false,
    this.error,
  });

  final String searchQuery;
  final AppealsFilter filter;
  final Set<String> bookedIds;
  final List<ExamBookingEntity> examBookings;
  final bool isLoading;
  final bool loaded;
  final String? error;

  AppealsState copyWith({
    String? searchQuery,
    AppealsFilter? filter,
    Set<String>? bookedIds,
    List<ExamBookingEntity>? examBookings,
    bool? isLoading,
    bool? loaded,
    String? error,
    bool clearError = false,
  }) {
    return AppealsState(
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      bookedIds: bookedIds ?? this.bookedIds,
      examBookings: examBookings ?? this.examBookings,
      isLoading: isLoading ?? this.isLoading,
      loaded: loaded ?? this.loaded,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AppealsController extends Notifier<AppealsState> {
  @override
  AppealsState build() => const AppealsState();

  void search(String value) => state = state.copyWith(searchQuery: value);

  void setFilter(AppealsFilter value) => state = state.copyWith(filter: value);

  void book(String examId) {
    state = state.copyWith(bookedIds: {...state.bookedIds, examId});
  }

  Future<void> loadAvailableAppeals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        ref.read(getBookableExamSessionsUseCaseProvider).call(),
        ref.read(getActiveExamBookingsUseCaseProvider).call(),
      ]);
      final bookableSessions = results[0];
      final activeBookings = results[1];

      final coursesByCode = <String, AcademicExamCourseEntity>{
        for (final course in ref.read(careerProvider).courses)
          if (course.code.trim().isNotEmpty)
            course.code.trim().toUpperCase(): course,
      };

      final bookingsByKey = <String, Map<String, dynamic>>{
        for (final booking in activeBookings)
          _bookingKey(booking['adsceId'], booking['appId']): booking,
      };

      final exams = bookableSessions
          .map(
            (session) =>
                _mapBookableSession(session, coursesByCode, bookingsByKey),
          )
          .toList(growable: false)
        ..sort((a, b) => a.date.compareTo(b.date));

      state = state.copyWith(
        examBookings: exams,
        isLoading: false,
        loaded: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        loaded: true,
        error: error.toString(),
      );
    }
  }

  String _bookingKey(Object? adsceId, Object? appId) => '${adsceId}_$appId';

  ExamBookingEntity _mapBookableSession(
    Map<String, dynamic> session,
    Map<String, AcademicExamCourseEntity> coursesByCode,
    Map<String, Map<String, dynamic>> bookingsByKey,
  ) {
    final adCod = (session['adCod'] as String? ?? '').trim();
    final course = coursesByCode[adCod.toUpperCase()];
    final matchingBooking = bookingsByKey[_bookingKey(
      session['adsceId'],
      session['appId'],
    )];
    final isBooked = matchingBooking != null;

    final registrationEnd = _parseCinecaDate(
      session['dataFineIscr'] as String?,
    );
    final examStart =
        _parseCinecaDate(
          (matchingBooking?['dataOraTurno'] as String?) ??
              session['dataInizioApp'] as String?,
        ) ??
        DateTime.now();

    return ExamBookingEntity(
      id: (session['appelloId'] ?? session['appId'] ?? examStart.toIso8601String())
          .toString(),
      courseName: course?.name ?? _textOrFallback(session['adDes'], 'Corso non disponibile'),
      courseAcronym: adCod.isEmpty ? 'N/D' : adCod,
      professor: _textOrFallback(session['docente'], 'Docente non disponibile'),
      date: examStart,
      time: _timeOf(session['oraEsa'] as String?, examStart),
      location: _textOrFallback(
        matchingBooking?['aulaDes'],
        'Aula non disponibile',
      ),
      building: 'Edificio non disponibile',
      enrollDeadline: registrationEnd ?? examStart,
      spotsTotal: 0,
      spotsLeft:
          (matchingBooking?['numIscritti'] as num?)?.toInt() ??
          (session['numIscritti'] as num?)?.toInt() ??
          0,
      status: isBooked
          ? ExamBookingStatus.booked
          : _statusFromCineca(session['stato'] as String?, registrationEnd),
      credits: course?.credits ?? 0,
      year: course?.year ?? 0,
    );
  }

  ExamBookingStatus _statusFromCineca(
    String? cinecaStatus,
    DateTime? registrationEnd,
  ) {
    final status = (cinecaStatus ?? '').trim().toUpperCase();
    if (status == 'S' || status == 'CHIUSO') return ExamBookingStatus.closed;
    if (registrationEnd == null) return ExamBookingStatus.open;
    final remaining = registrationEnd.difference(DateTime.now());
    if (remaining.isNegative) return ExamBookingStatus.closed;
    return remaining.inDays <= 3
        ? ExamBookingStatus.closing
        : ExamBookingStatus.open;
  }

  String _timeOf(String? rawTime, DateTime fallback) {
    final text = rawTime?.trim();
    if (text != null && text.isNotEmpty) return text;
    return '${fallback.hour.toString().padLeft(2, '0')}:${fallback.minute.toString().padLeft(2, '0')}';
  }

  String _textOrFallback(Object? value, String fallback) {
    final text = value as String?;
    if (text == null || text.trim().isEmpty) return fallback;
    return text.trim();
  }

  DateTime? _parseCinecaDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.trim();
    final parts = normalized.split(' ');
    final date = parts.first.split('/');
    if (date.length != 3) return DateTime.tryParse(normalized);
    final time = parts.length > 1 ? parts[1].split(':') : const <String>[];
    final year = int.tryParse(date[2]);
    final month = int.tryParse(date[1]);
    final day = int.tryParse(date[0]);
    if (year == null || month == null || day == null) {
      return DateTime.tryParse(normalized);
    }
    return DateTime(
      year,
      month,
      day,
      time.isNotEmpty ? int.tryParse(time[0]) ?? 0 : 0,
      time.length > 1 ? int.tryParse(time[1]) ?? 0 : 0,
    );
  }
}

final appealsControllerProvider =
    NotifierProvider<AppealsController, AppealsState>(AppealsController.new);

final allExamBookingsProvider = Provider<List<ExamBookingEntity>>((ref) {
  final state = ref.watch(appealsControllerProvider);
  return state.examBookings
      .map(
        (exam) => state.bookedIds.contains(exam.id)
            ? exam.copyWith(status: ExamBookingStatus.booked)
            : exam,
      )
      .toList(growable: false);
});

final visibleExamBookingsProvider = Provider<List<ExamBookingEntity>>((ref) {
  final state = ref.watch(appealsControllerProvider);
  final query = state.searchQuery.trim().toLowerCase();
  final exams = ref.watch(allExamBookingsProvider);

  final filteredExams = switch (state.filter) {
    AppealsFilter.all => exams,
    AppealsFilter.booked =>
      exams
          .where((exam) => exam.status == ExamBookingStatus.booked)
          .toList(growable: false),
    AppealsFilter.available =>
      exams
          .where(
            (exam) =>
                exam.status == ExamBookingStatus.open ||
                exam.status == ExamBookingStatus.closing,
          )
          .toList(growable: false),
    AppealsFilter.recommended => const <ExamBookingEntity>[],
  };

  return filteredExams
      .where((exam) {
        final matchesSearch =
            query.isEmpty ||
            exam.courseName.toLowerCase().contains(query) ||
            exam.professor.toLowerCase().contains(query) ||
            exam.location.toLowerCase().contains(query);
        return matchesSearch;
      })
      .toList(growable: false);
});

final suggestedExamsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(academicRepositoryProvider).getSuggestedExams();
});

final recommendedExamBookingsProvider = Provider<List<RecommendedExamBooking>>((
  ref,
) {
  final state = ref.watch(appealsControllerProvider);
  final career = ref.watch(careerProvider);
  final exams = ref.watch(allExamBookingsProvider);
  final suggested = ref
      .watch(suggestedExamsProvider)
      .maybeWhen(
        data: (items) => items,
        orElse: () => const <Map<String, dynamic>>[],
      );

  final query = state.searchQuery.trim().toLowerCase();

  final examsByCode = <String, List<ExamBookingEntity>>{};
  final examsByName = <String, List<ExamBookingEntity>>{};

  for (final exam in exams) {
    if (exam.courseAcronym.trim().isNotEmpty) {
      examsByCode
          .putIfAbsent(_normalize(exam.courseAcronym), () => [])
          .add(exam);
    }
    examsByName.putIfAbsent(_normalize(exam.courseName), () => []).add(exam);
  }

  final suggestedKeys = suggested
      .map((item) {
        final code = item['adCod'] ?? item['codice'] ?? item['code'];
        final name = item['adDes'] ?? item['nome'] ?? item['name'];
        return _normalize((code ?? name ?? '').toString());
      })
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  final pendingCourses = career.courses.where((course) {
    if (course.passed) return false;

    return query.isEmpty ||
        course.name.toLowerCase().contains(query) ||
        course.code.toLowerCase().contains(query);
  }).toList();

  if (suggestedKeys.isNotEmpty) {
    pendingCourses.sort((first, second) {
      final firstIndex = _suggestedIndex(first, suggestedKeys);
      final secondIndex = _suggestedIndex(second, suggestedKeys);

      if (firstIndex != secondIndex) return firstIndex.compareTo(secondIndex);
      return _comparePendingCourses(first, second);
    });
  } else {
    pendingCourses.sort(_comparePendingCourses);
  }

  return pendingCourses
      .map((course) {
        final matchingExams =
            examsByCode[_normalize(course.code)] ??
            examsByName[_normalize(course.name)] ??
            const <ExamBookingEntity>[];

        return RecommendedExamBooking(
          course: course,
          appeal: _bestExamBooking(matchingExams),
        );
      })
      .toList(growable: false);
});

int _suggestedIndex(
  AcademicExamCourseEntity course,
  List<String> suggestedKeys,
) {
  final code = _normalize(course.code);
  final name = _normalize(course.name);

  final index = suggestedKeys.indexWhere((key) => key == code || key == name);

  return index == -1 ? 9999 : index;
}

int _comparePendingCourses(
  AcademicExamCourseEntity first,
  AcademicExamCourseEntity second,
) {
  final creditsComparison = first.credits.compareTo(second.credits);
  if (creditsComparison != 0) return creditsComparison;
  final yearComparison = first.year.compareTo(second.year);
  if (yearComparison != 0) return yearComparison;
  final semesterComparison = first.semester.compareTo(second.semester);
  if (semesterComparison != 0) return semesterComparison;
  return first.name.compareTo(second.name);
}

ExamBookingEntity? _bestExamBooking(List<ExamBookingEntity> exams) {
  if (exams.isEmpty) return null;
  final sorted = [...exams]
    ..sort((first, second) {
      final priorityComparison = _examPriority(
        first,
      ).compareTo(_examPriority(second));
      if (priorityComparison != 0) return priorityComparison;
      return first.date.compareTo(second.date);
    });
  return sorted.first;
}

int _examPriority(ExamBookingEntity exam) {
  return switch (exam.status) {
    ExamBookingStatus.open || ExamBookingStatus.closing => 0,
    ExamBookingStatus.booked => 1,
    ExamBookingStatus.closed => 2,
  };
}

String _normalize(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
}