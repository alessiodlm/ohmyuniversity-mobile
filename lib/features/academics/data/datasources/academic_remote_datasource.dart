import 'package:dio/dio.dart';

import '../../domain/entities/course_questionnaire_entity.dart';
import '../../domain/entities/exam_booking_history_entity.dart';
import '../../domain/exceptions/career_data_exception.dart';
import '../models/career_api_models.dart';

class AcademicRemoteDataSource {
  const AcademicRemoteDataSource(this._dio);

  final Dio _dio;
  Future<List<Map<String, dynamic>>> getSuggestedExams() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/career/recommendations',
      );

      final data = response.data;
      if (data == null) return const [];

      final rawItems =
          data['esami'] as List<dynamic>? ??
          data['suggeriti'] as List<dynamic>? ??
          data['appelli'] as List<dynamic>? ??
          const [];

      return rawItems.whereType<Map<String, dynamic>>().toList(growable: false);
    } on DioException catch (_) {
      return const [];
    }
  }

  Future<CareerApiDataModel> getCareerData() async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>('/v1/career/transcript'),
        _dio.get<Map<String, dynamic>>('/v1/career/grades'),
        _dio.get<Map<String, dynamic>>('/v1/career/study-plan'),
      ]);
      final transcriptJson = responses[0].data;
      final metricsJson = responses[1].data;
      final studyPlanJson = responses[2].data;
      if (transcriptJson == null ||
          metricsJson == null ||
          studyPlanJson == null) {
        throw const CareerDataException(
          'Il servizio ha restituito dati incompleti.',
        );
      }
      return CareerApiDataModel(
        transcript: TranscriptResponseModel.fromJson(transcriptJson),
        metrics: CareerMetricsModel.fromJson(metricsJson),
        studyPlan: StudyPlanResponseModel.fromJson(studyPlanJson),
      );
    } on DioException catch (error) {
      throw CareerDataException(_messageFor(error));
    }
  }

  Future<List<ExamBookingHistoryEntity>> getExamBookingHistory(
    String password,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/exams/bookings/legacy',
        data: {'password': password},
      );

      final bookings = response.data?['prenotazioni'] as List<dynamic>? ?? [];

      return bookings
          .whereType<Map<String, dynamic>>()
          .map(_mapBooking)
          .toList(growable: false);
    } on DioException catch (error) {
      throw CareerDataException(switch (error.response?.statusCode) {
        401 => "Sessione scaduta. Effettua nuovamente l'accesso.",
        503 => 'Le prenotazioni non sono momentaneamente disponibili.',
        _ => 'Impossibile caricare lo storico prenotazioni.',
      });
    }
  }

  Future<List<Map<String, dynamic>>> getBookableExamSessions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/exams/bookable',
      );
      final appeals = response.data?['appelli'] as List<dynamic>? ?? [];
      return appeals
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw CareerDataException(switch (error.response?.statusCode) {
        401 => "Sessione scaduta. Effettua nuovamente l'accesso.",
        503 => 'Gli appelli non sono momentaneamente disponibili.',
        _ => 'Impossibile caricare gli appelli disponibili.',
      });
    }
  }

  Future<List<Map<String, dynamic>>> getActiveExamBookings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/exams/bookings',
      );
      final bookings = response.data?['prenotazioni'] as List<dynamic>? ?? [];
      return bookings
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } on DioException catch (error) {
      throw CareerDataException(switch (error.response?.statusCode) {
        401 => "Sessione scaduta. Effettua nuovamente l'accesso.",
        503 => 'Le prenotazioni non sono momentaneamente disponibili.',
        _ => 'Impossibile caricare le prenotazioni attive.',
      });
    }
  }

  Future<List<CourseQuestionnaireEntity>> getQuestionnaires() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/exams/surveys',
      );
      final pending = response.data?['daCompilare'] as List<dynamic>? ?? [];
      final completed = response.data?['compilati'] as List<dynamic>? ?? [];
      return [
        ...pending.whereType<Map<String, dynamic>>().map(
          (json) => _mapQuestionnaire(json, CourseQuestionnaireStatus.pending),
        ),
        ...completed.whereType<Map<String, dynamic>>().map(
          (json) =>
              _mapQuestionnaire(json, CourseQuestionnaireStatus.completed),
        ),
      ];
    } on DioException catch (error) {
      throw CareerDataException(_messageFor(error));
    }
  }

  CourseQuestionnaireEntity _mapQuestionnaire(
    Map<String, dynamic> json,
    CourseQuestionnaireStatus status,
  ) {
    return CourseQuestionnaireEntity(
      id: (json['adsceId'] ?? json['adCod'] ?? json['adDes']).toString(),
      courseName: _textOrFallback(json['adDes'], 'Corso non disponibile'),
      professor: 'Docente non disponibile',
      type: _textOrFallback(json['adCod'], 'Questionario didattica'),
      status: status,
      completedAt: status == CourseQuestionnaireStatus.completed
          ? DateTime.now()
          : null,
    );
  }

  ExamBookingHistoryEntity _mapBooking(Map<String, dynamic> json) {
    return ExamBookingHistoryEntity(
      id: (json['applistaId'] as num).toInt(),
      activityId: (json['adId'] as num?)?.toInt(),
      enrollmentActivityId: (json['adsceId'] as num?)?.toInt(),
      courseCode: _textOrFallback(
        json['adStuCod'],
        _textOrFallback(json['adCod'], ''),
      ),
      courseName: _textOrFallback(
        json['adStuDes'],
        _textOrFallback(json['adDes'], ''),
      ),
      bookingDate: _parseDateTime(json['dataInizioIscr'] as String?),
      examDate: _parseDateTime(json['dataOraTurno'] as String?),
      credits: (json['cfu'] as num?)?.toDouble() ?? 0,
      grade: (json['votoEsa'] as num?)?.toInt(),
      passed: json['superato'] as bool? ?? false,
      absent: json['assente'] as bool? ?? false,
      withdrawn: json['ritirato'] as bool? ?? false,
    );
  }

  DateTime? _parseDateTime(String? value) {
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

  String _textOrFallback(Object? value, String fallback) {
    final text = value as String?;
    if (text == null || text.trim().isEmpty) return fallback;
    return text.trim();
  }

  String _messageFor(DioException error) {
    return switch (error.response?.statusCode) {
      401 => "Sessione scaduta. Effettua nuovamente l'accesso.",
      503 => 'I dati ESSE3 non sono momentaneamente disponibili.',
      _
          when error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout =>
        'Tempo di connessione scaduto.',
      _ => 'Impossibile caricare i dati della carriera.',
    };
  }
}