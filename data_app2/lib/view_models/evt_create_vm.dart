import 'dart:collection';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_suggestion_engine.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

const nLoad = 500;

/// Event creation logic
class EvtCreateVm extends ChangeNotifier {
  final DBService _db;
  final EvtTypeManagerPersist _typeManager;
  final bool _autoLowerCase;
  final FrequencySuggestionEngine _suggestEngine;
  bool isReady = false;

  /// Loaded events. CHRONOLOGICALLY SORTED
  List<EvtRec> _evts = [];
  UnmodifiableListView<EvtRec> get evts => _evts.unmodifiable;

  /// Get last event, if not stopped
  EvtRec? get current {
    final last = evts.lastOrNull;
    return (last?.end == null) ? last : null;
  }

  EvtTypeRec? get currentType {
    final evt = current;
    if (evt == null) return null;
    final typ = _typeManager.typeFromId(evt.typeId);
    if (typ == null) {
      Logger.root.severe("Current event has unknown type");
      return null;
    }

    return typ;
  }

  EvtCreateVm(this._db, this._typeManager, this._autoLowerCase)
    : _suggestEngine = FrequencySuggestionEngine(_typeManager);

  /// update latest-list and eventcounts
  Future<void> load() async {
    await Future.delayed(Duration(milliseconds: 400));
    final evts = (await _db.evts.latest(nLoad)).toList();
    _evts = evts;
    isReady = true;
    notifyListeners();
  }

  /// Add a event of a "known" type, for example by clicking suggestion.
  Future<void> addEventByTypeId(int typeId, {DateTime? start}) async {
    // start now, null end
    final draft = EvtDraft.inCurrentTZ(typeId, start: start ?? DateTime.now(), end: null);
    final newId = await _db.evts.create(draft);
    _evts.add(draft.toRec(newId));
    notifyListeners();
  }

  /// Add a event of a possibly "unknown" type.
  Future<void> addEventByName(String name, {DateTime? start}) async {
    // optionally auto lowercase
    if (_autoLowerCase) name = name.toLowerCase();

    final typ = await _typeManager.fromNameOrCreate(name);
    await addEventByTypeId(typ.id, start: start);
  }

  /// Set event end to now
  Future<void> stopCurrent() async {
    final evt = current;
    if (evt == null) return; // shouldnt happen

    if (evt.end != null) {
      Logger.root.warning("tried to stop an already stopped event");
      return;
    }
    // edit
    final d = evt.toDraft()..end = LocalDateTime.now();
    final updated = d.toRec(evt.id);
    // update in DB
    await _db.evts.update(updated);

    // update in in-memory list
    _evts[_evts.length - 1] = updated;
    notifyListeners();
  }

  Iterable<EvtTypeRec> get suggestions {
    return _suggestEngine.get(_evts);
  }

  Color colorFor(EvtTypeRec rec, double spread) {
    return _typeManager.colorFor(rec, spread);
  }
}
