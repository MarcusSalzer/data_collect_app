import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/summary_with_period_aggs.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:data_app2/util/summary_period_aggs.dart';
import 'package:flutter/material.dart';

class MultiEvtSummaryVM extends ChangeNotifier {
  final AppState _app;
  final Iterable<int> _typeIds;
  final List<EvtTypeRec> _typeRecs; // resolved from typeIds
  int get nTypes => _typeIds.length;
  // aggregation frequency
  GroupFreq _freq = GroupFreq.month; // default for initial summary
  GroupFreq get freq => _freq;

  ProcessState<SummaryWithPeriodAggs> state = Loading();

  List<EvtRec>? _evts;

  MultiEvtSummaryVM(this._typeIds, this._app)
    : _typeRecs = _typeIds
          .map(
            (i) =>
                _app.evtTypeManager.resolveById(i) ??
                EvtTypeRec(name: "Unknown"),
          )
          .toList() // resolve type ids and set to unknown if missing
          ;
  void setFreq(GroupFreq? f) {
    if (f == null) return;

    _freq = f;
    final evts = _evts;
    if (evts != null) {
      state = Ready(computeSummary(evts));
    }
    notifyListeners();
  }

  SummaryWithPeriodAggs computeSummary(List<EvtRec> evts) {
    return SummaryWithPeriodAggs(
      computeAggs(evts, _typeRecs, _freq),
      _typeRecs,
      _freq,
      evts.length,
    );
  }

  /// Load events and compute summary
  Future<void> load() async {
    final evts = (await _app.db.events.filteredLocalTime(
      typeIds: _typeIds,
    )).map((e) => EvtRec.fromIsar(e)).toList();

    _evts = evts;

    state = Ready(computeSummary(evts));
    notifyListeners();
  }
}
