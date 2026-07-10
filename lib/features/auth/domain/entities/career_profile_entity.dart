class CareerProfileEntity {
  const CareerProfileEntity({
    required this.universityId,
    required this.universityName,
    required this.studentId,
    required this.enrollmentId,
    required this.studentNumber,
    required this.courseName,
    required this.courseCode,
    required this.degreeCourseId,
    required this.courseTypeCode,
    required this.studentStatus,
    required this.studentStatusDescription,
    required this.courseYear,
    required this.courseDurationYears,
    required this.academicYear,
    required this.active,
    required this.graduated,
  });

  final String universityId;
  final String universityName;
  final int? studentId;
  final int? enrollmentId;
  final String studentNumber;
  final String courseName;
  final String courseCode;
  final int? degreeCourseId;
  final String courseTypeCode;
  final String studentStatus;
  final String studentStatusDescription;
  final int? courseYear;
  final int? courseDurationYears;
  final int? academicYear;
  final bool active;
  final bool graduated;
}