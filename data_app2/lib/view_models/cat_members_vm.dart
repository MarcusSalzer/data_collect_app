import 'dart:collection';

import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';

class EvtCatMembersVm extends ChangeNotifier {
  final EvtCatRec _cat;
  final DBService _db;
  final EvtTypeManagerPersist _typeManager;

  EvtCatMembersVm(this._cat, this._db, this._typeManager);

  Iterable<int> danglingTypeRefs = {};

  List<EvtTypeRec>? _types;

  UnmodifiableListView<EvtTypeRec>? get types => _types?.unmodifiable;

  EvtTypeRec? eventType(int id) {
    return _typeManager.typeFromId(id);
  }

  Future<void> load() async {
    // load the types
    _types = (await _db.evtTypes.inCategory(_cat.id)).toList();
    notifyListeners();
  }

  /// remove a type from this category
  Future<void> unlink(EvtTypeRec type) async {
    await _db.evtTypes.unlinkCategory(type);
    _types?.remove(type);
    notifyListeners();
  }
}
