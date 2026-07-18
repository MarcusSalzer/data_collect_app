import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/location.dart';

class LocationCsvCodecHuman extends CsvCodecRW<LocationDraft> {
  LocationCsvCodecHuman({super.sep});
  @override
  get schema => CsvSchemasConst.locationHuman;

  @override
  build(CsvRow r) {
    return LocationDraft(r.req("name"), r.reqDouble("lat"), r.reqDouble("lng"));
  }

  @override
  toRow(d) {
    return CsvRow({
      "name": d.name,
      "lat": d.lat.toString(),
      "lng": d.lng.toString(),
    });
  }
}

class LocationCsvCodecRaw extends CsvCodecRW<LocationRec> {
  LocationCsvCodecRaw({super.sep});
  @override
  get schema => CsvSchemasConst.locationHuman;

  @override
  build(CsvRow r) => LocationRec(r.reqInt("id"), name: r.req("name"), lat: r.reqDouble("lat"), lng: r.reqDouble("lng"));

  @override
  toRow(d) => CsvRow({
    "id": d.id.toString(),
    "name": d.name,
    "lat": d.lat.toString(),
    "lng": d.lng.toString(),
  });
}
