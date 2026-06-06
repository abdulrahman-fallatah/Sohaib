import 'package:sqlite3/sqlite3.dart';
import 'package:sohaib/objects.dart';

class StudentDao {
  final Database _db;

  StudentDao(this._db);

  void addStudentWithClass(String name, String className) {
    _db.execute('BEGIN');
    final stmt = _db.prepare(
      'INSERT INTO Students (FullName, presentDays, absentDays) VALUES (?,?,?)',
    );
    final assignStmt = _db.prepare(
      'INSERT INTO S_C (student_id, class_id) VALUES (?, ?)',
    );

    try {
      stmt.execute([name, 0, 0]);
      final studentId = _db.lastInsertRowId;

      final classResult = _db.select(
        'SELECT class_id FROM classes WHERE Class_name = ?',
        [className],
      );

      if (classResult.isEmpty) {
        throw FormatException(
          'الفصل ($className) غير موجود! يرجى إضافة الفصل أولاً.',
        );
      }

      final classID = classResult.first['class_id'];

      assignStmt.execute([studentId, classID]);
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.close();
      assignStmt.close();
    }
  }

  List<Student> getAllStudents() {
    final ResultSet rows = _db.select('SELECT * FROM Students');
    return rows.map((e) => Student.fromMap(e)).toList();
  }

  List<Student> getStudentsByClass(int classId) {
    final ResultSet studentRows = _db.select(
      '''
      SELECT * FROM Students
      JOIN S_C on Students.student_id = S_C.student_id
      WHERE S_C.class_id = ?
      GROUP BY Students.student_id
    ''',
      [classId],
    );
    return studentRows.map((e) => Student.fromMap(e)).toList();
  }

  List<Map<String, dynamic>> getStudentAttendanceDetails(String studentId) {
    final ResultSet rows = _db.select(
      '''
      SELECT * FROM Students
      JOIN Attendance ON Students.student_id = Attendance.student_id
      JOIN S_C ON Students.student_id = S_C.student_id
      JOIN Classes ON S_C.class_id = Classes.class_id
      WHERE Students.student_id = ?
    ''',
      [studentId],
    );

    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void recordAttendance(String? status, Student student, String today) {
    if (status == '0' || status == '1') {
      _db.execute('BEGIN');
      final stmt = _db.prepare(
        'INSERT INTO Attendance (student_id, date, status) VALUES (?,?,?)',
      );
      final stmt1 = _db.prepare(
        'UPDATE Students SET ${status == '0' ? 'absentDays' : 'presentDays'} = ? WHERE student_id = ?',
      );

      try {
        if (status == '0') {
          stmt.execute([student.studentID, today, 'غائب']);
          stmt1.execute([student.absentDays + 1, student.studentID]);
        } else {
          stmt.execute([student.studentID, today, 'حاضر']);
          stmt1.execute([student.presentDays + 1, student.studentID]);
        }
        _db.execute('COMMIT');
      } catch (e) {
        _db.execute('ROLLBACK');
        rethrow;
      } finally {
        stmt.close();
        stmt1.close();
      }
    }
  }

  void deleteStudent(String studentID) {
    _db.execute('BEGIN');

    try {
      _db.execute('DELETE FROM Attendance WHERE Attendance.student_id = ?', [
        studentID,
      ]);
      _db.execute('DELETE FROM S_C WHERE S_C.student_id = ?', [studentID]);
      _db.execute('DELETE FROM Students WHERE Students.student_id = ?', [
        studentID,
      ]);

      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void updateStudentName(String studentID, String? newName) {
    _db.execute('BEGIN');
    final stmt = _db.prepare(
      'UPDATE Students SET fullName = ? WHERE student_id = ?',
    );

    try {
      stmt.execute([newName, studentID]);
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.close();
    }
  }

  void updateStudentClass(String studentId, String newClassName) {
    _db.execute('BEGIN');
    final stmt = _db.prepare(
      'UPDATE S_C SET class_id = ? WHERE student_id = ?',
    );

    try {
      final classResult = _db.select(
        'SELECT class_id FROM classes WHERE Class_name = ?',
        [newClassName],
      );

      if (classResult.isEmpty) {
        throw FormatException(
          'الفصل ($newClassName) غير موجود! يرجى التأكد من اسم الفصل .',
        );
      }

      final newClassId = classResult.first['class_id'];

      stmt.execute([newClassId, studentId]);
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.close();
    }
  }

  void updateAttendanceLog(
    String logId,
    String studentId,
    String newStatus,
    String oldStatus,
  ) {
    if (newStatus == oldStatus) return;

    _db.execute('BEGIN');
    try {
      _db.execute('UPDATE Attendance SET status = ? WHERE log_id = ?', [
        newStatus,
        logId,
      ]);

      if (newStatus == 'حاضر') {
        _db.execute(
          'UPDATE Students SET presentDays = presentDays + 1, absentDays = absentDays - 1 WHERE student_id = ?',
          [studentId],
        );
      } else {
        _db.execute(
          'UPDATE Students SET presentDays = presentDays - 1, absentDays = absentDays + 1 WHERE student_id = ?',
          [studentId],
        );
      }

      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}
