import 'package:sohaib/sohaib_logic.dart';
import 'package:hijri_date/hijri_date.dart';

void main() {
  HijriDate.setLocal('ar');
  final sohaib = Sohaib();
  sohaib.start();
}
