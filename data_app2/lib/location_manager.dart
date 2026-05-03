import 'package:data_app2/data/location.dart';
import 'package:flutter/material.dart';

/// Caches [Location] records for fast id/name-based lookup.
/// Intended to be held at app root and accessed globally.
class LocationManager extends ChangeNotifier {
  Map<int, LocationRec> _byId = {};
  Map<String, LocationRec> _byName = {};

  bool _ready = false;
  bool get isReady => _ready;

  List<LocationRec> get all => _byId.values.toList();

  /// Replace the entire cache (e.g. on app start or after a bulk change).
  void reloadFromModels(Iterable<LocationRec> locations) {
    _byId = {};
    _byName = {};
    for (final loc in locations) {
      _byId[loc.id] = loc;
      _byName[loc.name] = loc;
    }
    _ready = true;
    notifyListeners();
  }

  /// Insert or update a single location (after create/edit).
  void upsert(LocationRec loc) {
    _byId[loc.id] = loc;
    _byName[loc.name] = loc;
    notifyListeners();
  }

  /// Remove a location from the cache (after delete).
  void remove(int id, String name) {
    _byId.remove(id);
    _byName.remove(name);
    notifyListeners();
  }

  LocationRec? fromId(int? id) => _byId[id];
  LocationRec? fromName(String name) => _byName[name];

  void clearCache() {
    _byId = {};
    _byName = {};
  }
}
