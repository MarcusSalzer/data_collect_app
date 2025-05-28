// Text formatting
import 'package:data_app2/db_service.dart';
import 'package:intl/intl.dart';

(String, String) dateTimeFmt(DateTime? dt) {
  if (dt == null) {
    return ("__-__-__", "__:__");
  }
  return (DateFormat("yy-MM-dd").format(dt), DateFormat("HH:mm").format(dt));
}

(String, String) eventTimeFmt(Event evt) {
  final start = evt.start;
  final end = evt.end;
  final startText = start != null ? DateFormat("HH:mm").format(start) : "__:__";
  final endText = end != null ? DateFormat("HH:mm").format(end) : "__:__";
  return (startText, endText);
}

String durationHMFmt(Duration d) {
  final mins = d.inMinutes;
  if (mins <= 60) return "$mins min";
  return "${mins ~/ 60} h ${mins % 60} min";
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
