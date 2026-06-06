class ClassRoom {
  final int? classID;
  final String? className;

  ClassRoom({required this.classID, required this.className});

  factory ClassRoom.fromMap(Map map) {
    return ClassRoom(classID: map['class_id'], className: map['class_name']);
  }
}

class Student {
  int studentID;
  String fullName;
  String assignedClass;
  int presentDays;
  int absentDays;

  Student({
    required this.studentID,
    required this.fullName,
    required this.assignedClass,
    required this.presentDays,
    required this.absentDays,
  });

  factory Student.fromMap(Map map) {
    return Student(
      studentID: map['student_id'],
      fullName: map['fullName'] ?? "فارغ",
      assignedClass: map['className'] ?? "فارغ",
      presentDays: map['presentDays'] ?? 0,
      absentDays: map['absentDays'] ?? 0,
    );
  }
}
