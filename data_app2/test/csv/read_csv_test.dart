import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/location_manager.dart';
import 'package:test/test.dart';

void main() {
  final evtTypeMan = EvtTypeManager();
  final locMan = LocationManager();
  locMan.upsert(LocationRec(1, name: "Null island", lat: 0, lng: 0));
  evtTypeMan.reloadFromModels([EvtTypeRec(137, "phone call")], []);

  group("events", () {
    final codec = EvtCsvCodec(evtTypeMan, locMan);
    test("read event (Especially local datetimes...)", () {
      final lines = [
        "id,type,start_utc,start_offset_s,end_utc,end_offset_s,location",
        "7900,phone call,2026-02-10T14:29:20Z,3600,2026-02-10T14:32:44Z,7200,Null island",
      ];

      final rows = parseRows(lines).toList();
      expect(rows.length, lines.length - 1); // minus header

      final d = codec.decode(rows).first;
      expect(d.typeId, 137);

      expect(d.start, LocalDateTime.fromUtcISOAndOffset(utcIso: "2026-02-10T14:29:20Z", offsetMillis: 3_600_000));
      expect(d.start?.asUtc.hour, 14);
      expect(d.start?.offsetMillis, 3_600_000);
      expect(d.start?.asLocal.hour, 15);

      expect(d.end, LocalDateTime.fromUtcISOAndOffset(utcIso: "2026-02-10T14:32:44Z", offsetMillis: 7_200_000));
      expect(d.end?.asUtc.hour, 14);
      expect(d.end?.offsetMillis, 7_200_000);
      expect(d.end?.asLocal.hour, 16);

      // duration should be utc
      expect(d.duration, Duration(minutes: 3, seconds: 24));
    });
  });
}
