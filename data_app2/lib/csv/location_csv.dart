import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/location.dart';

class LocationCsvCodec extends CsvCodecRW<LocationDraft> {
  LocationCsvCodec({super.sep});
  @override
  get schema => CsvSchemasConst.location;

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
