import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/event_stats_compute.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';

/// Manage state for today-summary
class TodaySummaryVm extends ChangeNotifier {
  TodaySummaryVm(this._app) : _mode = _app.prefs.summaryMode {
    // refresh, for example if mode is changed
    _app.addListener(_updateMode);
  }
  final AppState _app;
  // keep track of today summary
  SummaryDataList? todaySummary;

  SummaryMode _mode;
  SummaryMode get mode => _mode;

  void _updateMode() {
    final newMode = _app.prefs.summaryMode;
    if (newMode != _mode) {
      _mode = newMode;
      refresh();
    }
  }

  Future<void> refresh() async {
    final evts = await _app.db.evts.filteredLocalTime(
      earliest: LocalDateTime.fromDateTimeLocalTZ(DateTime.now().startOfDay),
    );

    final tpe = timePerEvent(evts, limit: 16);

    switch (mode) {
      case SummaryMode.type:
        todaySummary = SummaryDataList(
          tpe.map((e) {
            final et = _app.evtTypeManager.resolveById(e.key);
            return SummaryItem(et?.name ?? "other", _app.colorFor(et), e.value);
          }).toList(),
        );
        break;
      case SummaryMode.category:
        todaySummary = await _groupByCategories(tpe);
        break;
    }

    notifyListeners();
  }

  Future<SummaryDataList> _groupByCategories(List<MapEntry<int, Duration>> byTypeId) async {
    final categories = await _app.db.evtCats.all();
    final idToCat = Map.fromEntries(categories.map((c) => MapEntry(c.id, c)));
    final byCat = <int?, Duration>{};

    for (var e in byTypeId) {
      final et = _app.evtTypeManager.resolveById(e.key);
      final cat = idToCat[et?.categoryId];
      byCat[cat?.id] = (byCat[cat?.id] ?? Duration.zero) + e.value;
    }

    return SummaryDataList(
      byCat.entries.map((e) {
        final cat = idToCat[e.key];
        return SummaryItem(cat?.name ?? "unknown", ColorEngine.defaultColor, e.value);
      }).toList(),
    );
  }

  @override
  void dispose() {
    _app.removeListener(_updateMode);
    super.dispose();
  }
}
