import 'dart:io';

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

Future<Iterable<EvtRec>> importEvtsCSV(String path) async {
  final file = File(path);

  final lines = await file.readAsLines();
  // compare header without spaces
  if (lines[0].replaceAll(" ", "") != eventsCsvHeader) {
    throw Exception("wrong CSV header: ${lines[0]}");
  }

  return parseCSV(lines.skip(1), EvtRec.fromRow);
}

Iterable<T> parseCSV<T>(
  Iterable<String> lines,
  T Function(List<String>) fromRow,
) sync* {
  for (final li in lines) {
    yield fromRow(li.split(","));
  }
}
