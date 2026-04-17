import 'package:data_app2/data/location.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/location_manager.dart';
import 'package:flutter/material.dart';

class LocationIndexVm extends ChangeNotifier {
  final DBService _db;
  final LocationManager _locationManager;

  LocationIndexVm(this._db, this._locationManager);

  Future<void> load() async {
    _locationManager.reloadFromModels(await _db.locations.all());
    // await refreshCounts();
    notifyListeners();
  }

  List<LocationRec>? get itemsSorted {
    if (!_locationManager.isReady) {
      return null;
    }
    final items = _locationManager.all;

    // Sort by descending (zeros at end)
    items.sort((a, b) {
      // Higher freq first
      return a.name.compareTo(b.name);
    });

    return items;
  }
}
