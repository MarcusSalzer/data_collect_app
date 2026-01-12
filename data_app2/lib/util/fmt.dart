// Text formatting
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/user_events.dart';
import 'package:intl/intl.dart';

/// Formatting functions
class Fmt {
  /// Name of a month
  static String monthName(DateTime dt) {
    return DateFormat("MMMM").format(dt);
  }

  /// Day name
  static String dayName(DateTime? dt) {
    if (dt == null) return "_";
    return DateFormat("EEEE").format(dt);
  }

  static String dayAbbr(DateTime? dt) {
    if (dt == null) return "___";
    return DateFormat("E").format(dt);
  }

  /// Day name month and day
  static String verboseDate(DateTime? dt, {GroupFreq? f}) {
    if (dt == null) {
      return "[unknown date]";
    }
    switch (f) {
      case GroupFreq.day || null:
        return DateFormat("EEEE MMMM dd").format(dt);
      case GroupFreq.week:
        return "w ${DateFormat("MMMM dd").format(dt.startOfweek)}";
      case GroupFreq.month:
        return DateFormat("MMMM").format(dt);
    }
  }

  /// Date yyyy-MM(-dd), or placeholder
  static String date(DateTime? dt, {GroupFreq? f}) {
    if (dt == null) {
      return ("__-__-__");
    }

    switch (f) {
      case GroupFreq.week || GroupFreq.day || null:
        return DateFormat("yyyy-MM-dd").format(dt);
      case GroupFreq.month:
        return DateFormat("yyyy-MM").format(dt);
    }
  }

  /// Time HH:mm, or placeholder
  static String time(DateTime? dt) {
    if (dt == null) {
      return ("__-__-__");
    }
    return DateFormat("HH:mm").format(dt);
  }

  /// string with year, month,... second
  static String dtSecond(DateTime? dt) {
    if (dt == null) {
      return "N/A";
    }
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(dt);
  }

  /// string with year, month,... second
  static String dtMinuteSimple(DateTime dt) {
    return DateFormat("yyyy-MM-dd_HHmm").format(dt) + (dt.isUtc ? "Z" : "");
  }

  /// string with year, month,... second
  static String dtSecondSimple(DateTime dt) {
    return DateFormat("yyyy-MM-ddTHH-mm-ss").format(dt) + (dt.isUtc ? "Z" : "");
  }

  /// Date and time strings, or placeholder
  static (String, String) dateTimeSeparate(DateTime? dt) {
    if (dt == null) {
      return ("__-__-__", "__:__");
    }
    return (DateFormat("yy-MM-dd").format(dt), DateFormat("HH:mm").format(dt));
  }

  /// start and end of event, with placeholders
  static (String, String) eventTimes(EvtRec evt, {useUtc = false}) {
    // get timestamps as UTC or local
    final start = useUtc ? evt.start?.asUtc : evt.start?.asLocal;
    final end = useUtc ? evt.end?.asUtc : evt.end?.asLocal;

    final startText = start != null
        ? DateFormat("HH:mm").format(start)
        : "__:__";
    final endText = end != null ? DateFormat("HH:mm").format(end) : "__:__";
    return (startText, endText);
  }

  static String durationHmVerbose(Duration? d) {
    if (d == null) {
      return "";
    }
    final mins = d.inMinutes;
    if (mins <= 60) return "$mins min";
    final minStr = (mins % 60).toString().padLeft(2);
    return "${mins ~/ 60} h $minStr min";
  }

  static String durationHm(Duration? d) {
    if (d == null) {
      return "__:__";
    }
    final hrs = d.inMinutes ~/ 60;
    final mins = d.inMinutes % 60;

    return "${hrs.toString().padLeft(2, "0")}:${mins.toString().padLeft(2, "0")}";
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
