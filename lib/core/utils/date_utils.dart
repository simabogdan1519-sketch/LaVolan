import 'package:intl/intl.dart';

class DateUtilsRo {
  static final DateFormat _displayFmt = DateFormat('dd MMM yyyy', 'ro_RO');
  static final DateFormat _shortFmt = DateFormat('dd.MM.yyyy', 'ro_RO');

  static String display(DateTime d) => _displayFmt.format(d);
  static String short(DateTime d) => _shortFmt.format(d);

  static int daysUntil(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final t = DateTime(target.year, target.month, target.day);
    return t.difference(today).inDays;
  }

  static String relativeRo(DateTime target) {
    final d = daysUntil(target);
    if (d < 0) return 'Expirat de ${-d} zile';
    if (d == 0) return 'Expiră astăzi';
    if (d == 1) return 'Expiră mâine';
    if (d < 30) return 'Expiră în $d zile';
    final months = (d / 30).floor();
    return 'Expiră în ~$months luni';
  }
}
