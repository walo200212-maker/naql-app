import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat('#,##0.00', 'fr_MA');
    return '${formatter.format(amount)} MAD';
  }

  static String formatCompact(double amount) {
    return '${amount.toStringAsFixed(0)} MAD';
  }

  static String formatCommission(double jobPrice) {
    final commission = jobPrice * 0.12;
    return formatCompact(commission);
  }
}
