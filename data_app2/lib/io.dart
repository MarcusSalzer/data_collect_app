import 'dart:io';

import 'package:data_app2/db_service.dart' show Event;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const eventsCsvHeader = "id,name,start,end";

/// Record class to hold an event
class EvtRec {
  final int? id;
  final String name;
  final DateTime? start;
  final DateTime? end;

  EvtRec(this.id, this.name, this.start, this.end);

  /// from [id] (optional), [name], [start], [end]
  factory EvtRec.fromRow(List<String> r) {
    if (r.length == 3) {
      return EvtRec(
        null,
        r[0].trim(),
        DateTime.tryParse(r[1].trim()),
        DateTime.tryParse(r[2].trim()),
      );
    } else if (r.length == 4) {
      return EvtRec(
        int.tryParse(r[0].trim()),
        r[1].trim(),
        DateTime.tryParse(r[2].trim()),
        DateTime.tryParse(r[3].trim()),
      );
    }
    throw FormatException("unexpected row length ${r.length}");
  }
  @override
  String toString() {
    return "Evt($id, $name, $start, $end)";
  }

  @override
  bool operator ==(Object other) =>
      other is EvtRec &&
      id == other.id &&
      name == other.name &&
      start == other.start &&
      end == other.end;

  @override
  int get hashCode => Object.hash(id, name, start, end);
}

/// Check what data is loaded
class EvtRecSummary {
  int cStart = 0;
  int cEnd = 0;
  int cTot = 0;

  DateTime? earliest;
  DateTime? latest;

  EvtRecSummary(Iterable<EvtRec> recs) {
    cStart = 0;
    cEnd = 0;
    cTot = 0;
    for (final r in recs) {
      final s = r.start;
      final e = r.end;
      if (s != null) {
        cStart++;
        if (earliest == null || s.isBefore(earliest!)) {
          earliest = s;
        }
      }
      if (e != null) {
        cEnd++;
        if (latest == null || e.isAfter(latest!)) {
          latest = s;
        }
      }
      cTot++;
    }
  }
}

/// Export events as CSV
Future<int> exportEvents(Iterable<Event> events) async {
  final nEvt = events.length;
  final lines = events.map((evt) {
    final nameSafe = evt.name.replaceAll(",", ";");
    return "${evt.id}, $nameSafe, ${evt.start?.toIso8601String()}, ${evt.end?.toIso8601String()}";
  });
  const eventsCsvHeader = "id,name,start,end";
  final csvContent = "$eventsCsvHeader\n${lines.join('\n')}";

  final dir = await defaultStoreDir();
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final n = DateTime.now();
  final file = File(
    p.join(dir.path,
        'events_${n.year}-${n.month}-${n.day}-${n.hour}-${n.minute}.csv'),
  );
  file.writeAsString(csvContent);
  return nEvt;
}

/// Import events form a CSV
/// Throws [FormatException] if CSV has unexpected header
Future<Iterable<EvtRec>> importEvtsCSV(String path) async {
  final file = File(path);

  final lines = await file.readAsLines();
  // compare header without spaces
  if (lines[0].replaceAll(" ", "") != eventsCsvHeader) {
    throw FormatException("wrong CSV header: ${lines[0]}");
  }

  return parseCSV(lines.skip(1), EvtRec.fromRow);
}

/// Parse each row with a function
Iterable<T> parseCSV<T>(
  Iterable<String> lines,
  T Function(List<String>) fromRow,
) sync* {
  for (final li in lines) {
    yield fromRow(li.split(","));
  }
}

/// Pick a user-accessible directory on Android
Future<Directory> defaultStoreDir() async {
  if (Platform.isAndroid) {
    return Directory('/storage/emulated/0/Documents/data_app');
  } else {
    final docDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(docDir.path, "data_app"));
  }
}
