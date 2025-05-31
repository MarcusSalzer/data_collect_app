// Text formatting
import 'package:data_app2/db_service.dart';
import 'package:data_app2/enums.dart';
import 'package:intl/intl.dart';

/// Formatting functions
class Fmt {
  /// Name of a month
  static String monthName(DateTime dt) {
    return DateFormat("MMMM").format(dt);
  }

  /// Day name
  static String dayName(DateTime dt) {
    return DateFormat("EEEE").format(dt);
  }

  /// Day name
  static String verboseDate(DateTime dt) {
    return DateFormat("EEEE MMMM dd").format(dt);
  }

  /// Date and time strings, or placeholder
  static String date(DateTime? dt) {
    if (dt == null) {
      return ("__-__-__");
    }
    return DateFormat("yy-MM-dd").format(dt);
  }

  /// Date and time strings, or placeholder
  static (String, String) dateTime(DateTime? dt) {
    if (dt == null) {
      return ("__-__-__", "__:__");
    }
    return (DateFormat("yy-MM-dd").format(dt), DateFormat("HH:mm").format(dt));
  }

  /// start and end of event, with placeholders
  static (String, String) eventTimes(Event evt) {
    final start = evt.start;
    final end = evt.end;
    final startText =
        start != null ? DateFormat("HH:mm").format(start) : "__:__";
    final endText = end != null ? DateFormat("HH:mm").format(end) : "__:__";
    return (startText, endText);
  }

  static String durationHM(Duration d) {
    final mins = d.inMinutes;
    if (mins <= 60) return "$mins min";
    final minStr = (mins % 60).toString().padLeft(2);
    return "${mins ~/ 60} h $minStr min";
  }
}

String dtDateFmt(DateTime? dt) {
  if (dt == null) {
    return "?";
  }
  return DateFormat("yyyy-MM-dd").format(dt);
}

String dtFreqFmt(DateTime dt, TableFreq freq) {
  switch (freq) {
    case TableFreq.free:
      return dt.toString();
    case TableFreq.day:
      return dtDateFmt(dt);
    case TableFreq.week:
      return "Week of ${dtDateFmt(dt)}";
  }
}
