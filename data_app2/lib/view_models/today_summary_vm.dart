import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_rec.dart';
import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/event_stats_compute.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';

/// Manage state for today-summary
class TodaySummaryVm extends ChangeNotifier {
  final AppState _app;
  // TODO include mode in app prefs
  SummaryMode mode = SummaryMode.category;
  // keep track of today summary
  SummaryDataList? todaySummary;

  TodaySummaryVm(this._app);

  Future<void> refresh() async {
    final evts = await _app.db.events.filteredLocalTime(
      earliest: LocalDateTime.fromDateTimeLocalTZ(DateTime.now().startOfDay),
    );

    final tpe = timePerEvent(evts.map((e) => EvtRec.fromIsar(e)), limit: 5);

    switch (mode) {
      case SummaryMode.evtType:
        todaySummary = SummaryDataList(
          tpe.map((e) {
            final et = _app.evtTypeManager.resolveById(e.key) ?? EvtTypeRec(name: "unknown");
            return SummaryItem(et.name, et.color, e.value);
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
    final categories = await _app.db.categories.all();
    final idToCat = Map.fromEntries(categories.map((c) => MapEntry(c.id, c)));
    final byCat = <int?, Duration>{};

    for (var e in byTypeId) {
      final et = _app.evtTypeManager.resolveById(e.key) ?? EvtTypeRec(name: "unknown");
      final cat = idToCat[et.categoryId];
      byCat[cat?.id] = (byCat[cat?.id] ?? Duration.zero) + e.value;
    }

    return SummaryDataList(
      byCat.entries.map((e) {
        final cat = idToCat[e.key];
        return SummaryItem(cat?.name ?? "unknown", ColorKey.base, e.value);
      }).toList(),
    );
  }
}
