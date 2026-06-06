import 'dart:io';
import 'dart:convert';

String? getValidInput(String phrase, void Function(String) validator) {
  while (true) {
    print(phrase);
    final input = stdin.readLineSync(encoding: utf8)?.trim();
    if (input == 'ت') return input;
    try {
      validator(input!);
      return input;
    } catch (e) {
      print(e);
      continue;
    }
  }
}

void onlyLetters(String input) {
  if (input.isEmpty) throw FormatException('الاسم لا يمكن أن يكون فارغًا');
  final regex = RegExp(r'^[\u0600-\u06FF\s]+$', unicode: true);
  if (!regex.hasMatch(input))
    throw FormatException('الاسم يجب أن يحتوي على حروف عربية فقط');
}

void onlyNumbers(String input) {
  if (input.isEmpty)
    throw FormatException("اختر رقم من الخيارات الموجودة أعلاه");
  final regex = RegExp(r'^\d+$');
  if (!regex.hasMatch(input)) throw FormatException("مسموح بالأرقم فقط");
}

void lettersAndNumbers(String input) {
  if (input.isEmpty) throw FormatException('اسم الفصل لا يمكن أن يكون فارغًا');
  final regex = RegExp(r'^[\u0621-\u064A0-9\s-]+$', unicode: true);
  if (!regex.hasMatch(input))
    throw FormatException('اسم الفصل يجب أن يحتوي على حروف عربية وأرقام فقط');
}
