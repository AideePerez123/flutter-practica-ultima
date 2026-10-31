import 'package:intl/intl.dart';

/// Formatting helpers shared across features.
class Formatters {
  Formatters._();

  static final NumberFormat _currency =
      NumberFormat.currency(locale: 'es_GT', symbol: 'Q', decimalDigits: 2);
  static final NumberFormat _integer = NumberFormat.decimalPattern('es_GT');
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _fileStamp = DateFormat('yyyyMMdd_HHmmss');

  static String currency(num value) => _currency.format(value);

  static String integer(num value) => _integer.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String fileStamp(DateTime value) => _fileStamp.format(value);
}
