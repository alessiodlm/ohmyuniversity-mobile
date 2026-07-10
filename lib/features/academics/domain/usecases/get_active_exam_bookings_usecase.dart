import '../repositories/academic_repository.dart';

class GetActiveExamBookingsUseCase {
  const GetActiveExamBookingsUseCase(this._repository);

  final AcademicRepository _repository;

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getActiveExamBookings();
  }
}
