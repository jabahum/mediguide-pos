import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy'); // e.g. 21 May 2026
    return formatter.format(date);
  }

  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy • HH:mm');
    return formatter.format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return formatDate(date);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
