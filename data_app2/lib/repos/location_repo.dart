import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

class LocationRepo extends CrudRepo<LocationRec, LocationDraft, LocationIsar> {
  LocationRepo(super.isar)
    : super(
        draftToIsar: (d) => LocationIsar(d.name, d.lat, d.lng),
        recToIsar: (r) => LocationIsar(r.name, r.lat, r.lng)..id = r.id,
        fromIsar: (i) => LocationRec(i.id, name: i.name, lat: i.lat, lng: i.lng),
      );

  @override
  IsarCollection<LocationIsar> get coll => isar.locationIsars;

  @override
  QueryBuilder<LocationIsar, int, QQueryOperations> get idProp => coll.where().idProperty();
}
