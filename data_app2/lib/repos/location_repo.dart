import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

class LocationRepo extends CrudRepo<LocationRec, LocationDraft, Location> {
  LocationRepo(super.isar)
    : super(
        draftToIsar: (d) => Location(d.name, d.lat, d.lng),
        recToIsar: (r) => Location(r.name, r.lat, r.lng)..id = r.id,
        fromIsar: (i) => LocationRec(i.id, name: i.name, lat: i.lat, lng: i.lng),
      );

  @override
  IsarCollection<Location> get coll => isar.locations;

  @override
  QueryBuilder<Location, int, QQueryOperations> get idProp => coll.where().idProperty();
}
