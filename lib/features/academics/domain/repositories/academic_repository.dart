import '../entities/career_snapshot_entity.dart';
import '../entities/exam_booking_history_entity.dart';

abstract interface class AcademicRepository {
  Future<CareerSnapshotEntity> getCareerSnapshot();
  Future<List<Map<String, dynamic>>> getSuggestedExams();

  Future<List<Map<String, dynamic>>> getBookableExamSessions();

  Future<List<Map<String, dynamic>>> getActiveExamBookings();

  Future<List<ExamBookingHistoryEntity>> getExamBookingHistory(String password);
  Future<List<ExamBookingHistoryEntity>?> getCachedExamBookingHistory();
}