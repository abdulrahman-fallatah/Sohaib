import 'dart:convert';
import 'dart:io';
import 'package:hijri_date/hijri_date.dart';
import 'objects.dart';
import 'validators.dart';
import 'daos/daos.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart';

final dbLocation = join(Directory.current.path, 'data', 'database.db');
final db = sqlite3.open(dbLocation);
final StudentDao studentDao = StudentDao(db);
final ClassDao classDao = ClassDao(db);

class Sohaib {
  void start() {
    while (true) {
      print(''':::::::قاعدة بيانات مركز صهيب الرومي:::::::
      :::::::القائمة الرئيسية:::::::
      1- إضافة طالب
      2- إضافة فصل
      3- عرض الطلاب
      4- تحضير الطلاب
      5- تعديل معلومات طالب
      6- حذف طالب
      7- إنهاء البرنامج''');
      final input = stdin.readLineSync(encoding: utf8)?.trim();
      switch (input) {
        case '1':
          print(':::::::إضافة طالب:::::::');
          String? name;
          String? className;

          name = getValidInput(
            'أدخل اسم الطالب، أو أدخل الحرف (ت) للتراجع إلى القائمة الرئيسية:',
            onlyLetters,
          );
          if (name == 'ت') break;

          className = getValidInput(
            'أدخل اسم الفصل الذي ينتمي إليه الطالب، أو أدخل الحرف (ت) للتراجع إلى القائمة الرئيسية:',
            lettersAndNumbers,
          );
          if (className == 'ت') break;

          try {
            studentDao.addStudentWithClass(name!, className!);
            print("تم إضافة الطالب بنجاح.");
          } catch (e) {
            print("حدث خطأ أثناء إضافة الطالب: $e");
          }

          break;
        case '2':
          print(':::::::إضافة فصل:::::::');
          String? className;

          className = getValidInput(
            'أدخل اسم الفصل الذي تريد إضافته، أو أدخل الحرف (ت) للتراجع إلى القائمة الرئيسية:',
            lettersAndNumbers,
          );
          if (className == 'ت') break;

          try {
            classDao.addClass(className!);
            print("تم إضافة الفصل بنجاح.");
          } catch (e) {
            print("حدث خطأ أثناء إضافة الفصل: $e");
          }
          break;
        case '3':
          print(':::::::إظهار الطلاب:::::::');

          final classes = classDao.getAllClasses();

          for (final room in classes) {
            print("الفصل: ${room.className}");

            final classStudents = studentDao.getStudentsByClass(room.classID!);

            if (classStudents.isEmpty) {
              print("لا يوجد طلاب مسجلين في هذا الفصل حاليا!");
            } else {
              for (final student in classStudents) {
                print(
                  "${student.studentID}) اسم الطالب: ${student.fullName}.\t أيام الحضور: ${student.presentDays}.\t أيام الغياب: ${student.absentDays}.",
                );
              }
              print("---------------------------");
            }
          }

          while (true) {
            print(
              "أدخل رقم الطالب لمشاهدة تفاصيله، أو أدخل الحرف (ت) للتراجع إلى القائمة الرئيسية: ",
            );
            final String? studentInput = stdin
                .readLineSync(encoding: utf8)
                ?.trim();

            if (studentInput == 'ت') {
              break;
            }

            if (studentInput == null || studentInput.isEmpty) continue;

            final studentDetails = studentDao.getStudentAttendanceDetails(
              studentInput,
            );

            if (studentDetails.isEmpty) {
              print(" لا يوجد طالب مسجل بهذا الرقم أو لا توجد سجلات تحضير له!");
              print("---------------------------");
              continue;
            }

            print(
              "${studentDetails[0]['student_id']}) اسم الطالب: ${studentDetails[0]['fullName']}.\t أيام الحضور: ${studentDetails[0]['presentDays']}.\t أيام الغياب: ${studentDetails[0]['absentDays']}.",
            );

            for (final row in studentDetails) {
              print("التاريخ: ${row['date']}.\t الحالة: ${row['status']}");
            }
            print("---------------------------");
          }
        case '4':
          print(':::::::تحضير الطلاب:::::::');
          final classes = classDao.getAllClasses();

          for (final room in classes) {
            final students = studentDao.getStudentsByClass(room.classID!);
            for (final student in students) {
              final status = getValidInput(
                "الفصل: ${room.className}, الطالب: ${student.fullName}\n حاضر؟ (أدخل 1 للحضور، 0 للغياب): ",
                onlyNumbers,
              );
              final today = HijriDate.now()
                  .toFormat('DDDD dd/MMMM/yyyy')
                  .toString();

              try {
                studentDao.recordAttendance(status, student, today);
                print(
                  status == '1'
                      ? "تم تحضير الطالب: ${student.fullName}"
                      : "تم تغييب الطالب: ${student.fullName}",
                );
              } catch (e) {
                print("حدث خطأ أثناء تحضير الطالب: $e");
              }
            }
          }
          break;
        case '5':
          print(':::::::تعديل معلومات طالب:::::::');
          final List<Student> students = studentDao.getAllStudents();
          if (students.isEmpty) {
            print("لا يوجد طلاب مسجلين في النظام حاليا");
            break;
          }

          for (final student in students) {
            print("${student.studentID}) ${student.fullName}");
          }

          final String? targetID = getValidInput(
            "أدخل رقم الطالب المراد تعديل معلوماته، أو أدخل الحرف (ت) للتراجع إلى القائمة الرئيسية: ",
            onlyNumbers,
          );
          if (targetID == 'ت') break;

          final exists = students.any(
            (s) => s.studentID.toString() == targetID,
          );
          if (!exists) {
            print("رقم الطالب غير صحيح أو غير مسجل في النظام!");
            break;
          }

          final studentDetails = studentDao.getStudentAttendanceDetails(
            targetID!,
          );
          print(
            "${studentDetails[0]['student_id']}) اسم الطالب: ${studentDetails[0]['fullName']}.\t الفصل: ${studentDetails[0]['class_name']}.\t أيام الحضور: ${studentDetails[0]['presentDays']}.\t أيام الغياب: ${studentDetails[0]['absentDays']}.",
          );

          print('''::: اختر العملية المطلوبة :::
          1- تعديل اسم الطالب
          2- نقل الطالب إلى فصل آخر
          3- تعديل الحضور/الغياب''');

          final option = stdin.readLineSync(encoding: utf8)?.trim();
          if (option == 'ت') break;

          switch (option) {
            case '1':
              final String? newName = getValidInput(
                "أدخل الاسم الجديد، أو أدخل (ت) للتراجع: ",
                onlyLetters,
              );
              if (newName == 'ت') break;

              try {
                studentDao.updateStudentName(targetID, newName!);
                print("تم تعديل اسم الطالب بنجاح.");
              } catch (e) {
                print("حدث خطأ أثناء تعديل الاسم: $e");
              }
              break;

            case '2':
              final String? newClass = getValidInput(
                "أدخل اسم الفصل الجديد المراد نقل الطالب إليه:",
                lettersAndNumbers,
              );
              if (newClass == 'ت') break;

              try {
                studentDao.updateStudentClass(targetID, newClass!);
                print("تم نقل الطالب إلى فصل ($newClass) بنجاح.");
              } catch (e) {
                print("فشلت عملية النقل: $e");
              }
              break;

            case '3':
              final List<String> logList = [];

              for (final n in studentDetails) {
                if (n['log_id'] != null) {
                  print(
                    "${n['log_id']}) التاريخ: ${n['date']}.\t الحالة: ${n['status']}",
                  );
                  logList.add(n['log_id'].toString());
                }
              }

              if (logList.isEmpty) {
                print("لا يوجد سجلات حضور أو غياب سابقة لهذا الطالب لتعديلها!");
                break;
              }

              final String? logIDInput = getValidInput(
                "اختر رقم السجل المراد تعديله، أو أدخل (ت) للتراجع: ",
                onlyNumbers,
              );
              if (logIDInput == 'ت') break;

              if (!logList.contains(logIDInput)) {
                print("لا يوجد تاريخ مسجل بهذا الرقم!");
                break;
              }

              final targetLog = studentDetails.firstWhere(
                (element) => element['log_id'].toString() == logIDInput,
              );
              final oldStatus = targetLog['status'];

              final String? newStatusInput = getValidInput(
                "أدخل (1) لتسجيل (حاضر)، أو (0) لتسجيل (غائب)، أو (ت) للتراجع: ",
                onlyNumbers,
              );
              if (newStatusInput == 'ت') break;

              if (newStatusInput != '0' && newStatusInput != '1') {
                print("خيار غير صالح!");
                break;
              }

              final newStatus = newStatusInput == '1' ? 'حاضر' : 'غائب';

              if (newStatus == oldStatus) {
                print("الطالب ($newStatus) بالفعل في هذا التاريخ!");
                break;
              }

              try {
                studentDao.updateAttendanceLog(
                  logIDInput!,
                  targetID,
                  newStatus,
                  oldStatus,
                );
                print("تم تعديل حالة الحضور بنجاح.");
              } catch (e) {
                print("حدث خطأ أثناء التعديل: $e");
              }
              break;

            default:
              print("خيار غير صالح");
          }
          break;
        case '6':
          print(':::::::حذف طالب:::::::');
          final studentRows = studentDao.getAllStudents();
          for (final student in studentRows) {
            print("${student.studentID}) ${student.fullName}");
          }
          final String? input = getValidInput(
            "أدخل رقم الطالب المراد حذفه",
            onlyNumbers,
          );

          try {
            studentDao.deleteStudent(input!);
            print("تم حذف الطالب بنجاح");
          } catch (e) {
            print("حدث خطأ أثناء حذف الطالب: $e");
          }
          break;
        case '7':
          print('إنهاء البرنامج');
          db.close();
          exit(0);
        default:
          print('خيار غير صالح');
      }
    }
  }

  void updateStudent(String studentID) {
    final studentDetails = db.select(
      '''SELECT * FROM Students
   JOIN S_C on Students.student_id = S_C.student_id
   JOIN Classes on S_C.class_id = Classes.class_id
   LEFT JOIN Attendance ON Students.student_id = Attendance.student_id
   WHERE Students.student_id = ?
   ''',
      [studentID],
    );

    print(
      "${studentDetails[0]['student_id']}) اسم الطالب: ${studentDetails[0]['fullName']}.\t الفصل: ${studentDetails[0]['class_name']}.\t أيام الحضور: ${studentDetails[0]['presentDays']}.\t أيام الغياب: ${studentDetails[0]['absentDays']}.",
    );

    for (final n in studentDetails) {
      print("التاريخ: ${n['date']}.\t الحالة: ${n['status']}");
    }

    print("---------------------------");
    print('''1) تغيير الاسم\n2) تغيير الفصل\n3) تعديل الحضور/الغياب''');
    final String? input = getValidInput(
      "اختر أحد الخيارات أعلاه، أو أدخل (ت) للتراجع إلى القائمة الرئيسية: ",
      onlyNumbers,
    );

    switch (input) {
      case '1':
        final String? newName = getValidInput(
          "أدخل الاسم الجديد، أو أدخل (ت) للتراجع: ",
          onlyLetters,
        );
        if (newName == 'ت') break;

        db.execute('BEGIN');
        final stmt = db.prepare(
          'UPDATE Students SET fullName = ? WHERE student_id = ?',
        );

        try {
          stmt.execute([newName, studentID]);
          db.execute('COMMIT');

          print("تم تغيير اسم الطالب بنجاح");
        } catch (e) {
          db.execute('ROLLBACK');
          print("حدث خطأ أثناء تغيير الاسم: $e");
        } finally {
          stmt.close();
        }
        break;
      case '2':
        final ResultSet allClasses = db.select('''SELECT * FROM Classes''');
        final List classIDList = [];

        for (final n in allClasses) {
          print("${n['class_id']}) ${n['class_name']}");
          classIDList.add(n['class_id']);
        }

        String? classID;

        while (true) {
          print(
            "اختصر فصلا من الفصول الظاهرة أعلاه عن طريق اختيار الرقم المجاور له، أو أدخل (ت) للتراجع: ",
          );
          final classIDInput = stdin.readLineSync(encoding: utf8)?.trim();

          if (classIDInput == 'ت') {
            return;
          } else if (classIDList.any((e) => e == int.parse(classIDInput!))) {
            classID = classIDInput;
            break;
          } else {
            print("لا يوجد فصل بهذا الرقم!");
          }
        }

        db.execute('BEGIN');
        final stmt = db.prepare(
          'UPDATE S_C SET Class_id = ? WHERE student_id = ?',
        );

        try {
          stmt.execute([int.parse(classID!), studentID]);
          db.execute('COMMIT');
          print("تم تغيير الفصل بنجاح");
        } catch (e) {
          db.execute('ROLLBACK');
          print("حدث خطأ أثناء تغيير الفصل: $e");
        } finally {
          stmt.close();
        }

        break;
      case '3':
        final List logList = [];
        int presentDays = studentDetails[0]['presentDays'];
        int absentDays = studentDetails[0]['absentDays'];

        for (final n in studentDetails) {
          if (n['log_id'] != null) {
            print(
              "${n['log_id']}) التاريخ: ${n['date']}.\t الحالة: ${n['status']}",
            );
            logList.add(n['log_id']);
          }
        }

        if (logList.isEmpty) {
          print("لا يوجد سجلات حضور أو غياب سابقة لهذا الطالب لتعديلها!");
          return;
        }

        late final String? logID;
        while (true) {
          final String? logIDInput = getValidInput(
            "اختر أحد الأرقام الظاهرة أعلاه لتغيير حالة الطالب في ذلك التاريخ، أو أدخل (ت) للتراجع: ",
            onlyNumbers,
          );

          if (logIDInput == 'ت') {
            return;
          } else if (logList.any((e) => e == int.parse(logIDInput!))) {
            logID = logIDInput;
            break;
          } else {
            print("لا يوجد تاريخ مسجل بهذا الرقم!");
          }
        }

        ResultSet statusList = db.select(
          'SELECT status FROM Attendance WHERE log_id = ?',
          [logID],
        );
        late String currentStatus;
        for (final status in statusList) {
          currentStatus = status['status'] == 'حاضر' ? '1' : '0';
        }
        late final String? newStatus;

        while (true) {
          print(
            "أدخل حالة الطالب الجديدة، أدخل (1) لتسجيل (حاضر)، أو (0) لتسجيل (غائب)، أو أدخل (ت) للتراجع: ",
          );
          final String? newStatusInput = stdin
              .readLineSync(encoding: utf8)
              ?.trim();

          if (newStatusInput == 'ت') {
            return;
          } else if (newStatusInput == currentStatus) {
            print("الطالب حاضر/غائب بالفعل في هذا التاريخ!");
          } else if (newStatusInput == '1' || newStatusInput == '0') {
            newStatus = newStatusInput == '1' ? 'حاضر' : 'غائب';
            break;
          } else {
            print("الإدخال خاطئ!");
          }
        }

        db.execute('BEGIN');
        final stmt = db.prepare(
          'UPDATE Attendance SET status = ? WHERE log_id = ?',
        );
        final stmt1 = db.prepare(
          'UPDATE Students SET presentDays = ?, absentDays = ? WHERE student_id = ?',
        );

        try {
          stmt.execute([newStatus, logID]);

          if (newStatus == 'حاضر') {
            presentDays++;
            absentDays--;
            stmt1.execute([presentDays, absentDays, studentID]);
          } else {
            presentDays--;
            absentDays++;
            stmt1.execute([presentDays, absentDays, studentID]);
          }

          db.execute('COMMIT');
          print("تم تعديل حالة حضور الطالب بنجاح.");
        } catch (e) {
          db.execute('ROLLBACK');
          print("حدث خطأ أثناء تعديل حالة حضور الطالب: $e");
        } finally {
          stmt.close();
          stmt1.close();
        }

        break;
    }
  }
}
