// Text formatting
import 'package:data_app2/db_service.dart' show Event;
import 'package:intl/intl.dart';

(String, String) eventTimeFormat(Event evt) {
  final start = evt.start;
  final end = evt.end;
  final startText = start != null ? DateFormat("HH:mm").format(start) : "__:__";
  final endText = end != null ? DateFormat("HH:mm").format(end) : "__:__";
  return (startText, endText);
}

durationHM(Duration d) {
  final mins = d.inMinutes;
  if (mins <= 60) return "$mins min";
  return "${mins ~/ 60} h ${mins % 60} min";
}
