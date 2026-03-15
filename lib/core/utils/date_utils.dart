import 'package:intl/intl.dart';

class AppDateUtils {
  const AppDateUtils._();

  static String formatShort(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
}
