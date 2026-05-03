import 'package:data_app2/contracts/data.dart';

/// Immutable domain record
class LocationRec implements Identifiable {
  const LocationRec(this.id, {required this.name, required this.lat, required this.lng});

  @override
  final int id;
  final String name;
  final double lat;
  final double lng;

  @override
  LocationDraft toDraft() {
    return LocationDraft(name, lat, lng);
  }

  @override
  String toString() {
    return "Location($id,$name,$lat,$lng)";
  }
}

/// For edit/create
class LocationDraft implements Draft<LocationRec> {
  LocationDraft(this.name, this.lat, this.lng);

  String name;
  double lat;
  double lng;

  @override
  LocationRec toRec(int id) {
    return LocationRec(id, name: name, lat: lat, lng: lng);
  }
}
