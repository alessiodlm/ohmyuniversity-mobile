import '../repositories/academic_repository.dart';

class GetBookableExamSessionsUseCase {
  const GetBookableExamSessionsUseCase(this._repository);

  final AcademicRepository _repository;

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getBookableExamSessions();
  }
}
