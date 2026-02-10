import 'dart:collection';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/util/stats.dart';
import 'package:flutter/material.dart';

const nFreq = 500;

class EventCreateViewVM extends ChangeNotifier {
  final AppState _app;
  final int? _nList; // default null -> all

  bool isLoading = true;

  List<EvtRec> _events = [];
  LinkedHashMap<int, int> _evtFreqs = LinkedHashMap<int, int>();
  List<EvtRec> get events => _events;
  Map<int, int> get evtFreqs => _evtFreqs;

  EventCreateViewVM(AppState appState) : _app = appState, _nList = 50 {
    load();
  }

  /// update latest-list and eventcounts
  Future<void> load() {
    return Future.wait([getLatest(), refreshCounts()]).then((_) {
      isLoading = false;
      notifyListeners();
    });
  }

  /// Add a event of a "known" type, for example by clicking suggestion.
  Future<void> addEventByTypeId(int typeId, {DateTime? start, DateTime? end}) async {
    final draft = EvtDraft.inCurrentTZ(typeId, start: start, end: end);
    final newId = await _app.db.evts.create(draft);
    _events.add(draft.toRec(newId));
    notifyListeners();
  }

  /// Add a event of a possibly "unknown" type.
  Future<void> addEventByName(String name, {DateTime? start, DateTime? end}) async {
    // optionally auto lowecase
    if (_app.autoLowerCase) {
      name = name.toLowerCase();
    }

    final typ = await _app.evtTypeManager.resolveOrCreate(name: name);
    await addEventByTypeId(typ.id, start: start, end: end);
  }

  Future<void> delete(EvtRec event) async {
    final id = event.id;
    await _app.db.evts.forceDelete(id);
    _events.remove(event);
    notifyListeners();
  }

  /// Save a new or updated event
  Future<EvtRec> updateEvent(EvtRec evt) async {
    await _app.db.evts.update(evt);
    notifyListeners();
    // TODO dont return?
    return evt;
  }

  /// Update in memory list, of reverse chronological events
  Future<void> getLatest() async {
    _events = (await _app.db.evts.latest(_nList)).toList().reversed.toList();
    notifyListeners();
  }

  List<int> eventSuggestions([int n = 20]) {
    var common = <int>[];
    for (var k in _evtFreqs.keys.take(n)) {
      common.add(k);
    }
    return common;
  }

  /// Count each event type
  Future<void> refreshCounts() async {
    final evts = await _app.db.evts.latest(nFreq);

    var counts = valueCounts<int>(evts.map((e) => e.typeId));

    _evtFreqs = LinkedHashMap.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}
