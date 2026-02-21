import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/summary_with_period_aggs.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:data_app2/util/summary_period_aggs.dart';
import 'package:flutter/material.dart';

class MultiEvtSummaryVM extends ChangeNotifier {
  final AppState _app;
  final Iterable<int> _typeIds;
  int get nTypes => _typeIds.length;
  // aggregation frequency
  GroupFreq _freq = GroupFreq.month; // default for initial summary
  GroupFreq get freq => _freq;

  ProcessState<SummaryWithPeriodAggs> state = Loading();

  // loaded after:
  List<EvtRec>? _evts;
  List<EvtTypeRec>? _typeRecs;

  MultiEvtSummaryVM(this._typeIds, this._app);
  void setFreq(GroupFreq? f) {
    if (f == null) return;

    _freq = f;
    final evts = _evts;
    final types = _typeRecs;
    if (evts != null && types != null) {
      state = Ready(computeSummary(evts, types));
    }
    notifyListeners();
  }

  SummaryWithPeriodAggs computeSummary(List<EvtRec> evts, List<EvtTypeRec> types) {
    return SummaryWithPeriodAggs(computeAggs(evts, types, _freq), types, _freq, evts.length);
  }

  /// Load events and types and compute summary
  Future<void> load() async {
    final types = (await _app.db.evtTypes.subset(_typeIds)).toList();
    final evts = (await _app.db.evts.filteredTypes(_typeIds)).toList();

    _evts = evts;
    _typeRecs = types;

    state = Ready(computeSummary(evts, types));
    notifyListeners();
  }
}
