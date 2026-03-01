import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/duration_summary_display_vm.dart';

/// Manage state for today-summary
class TodaySummaryDisplayVm extends DurationSummaryDisplayVm {
  TodaySummaryDisplayVm(super.dayStart, super.db, super.typeManager, super.colorSpread, super._summaryMode);

  @override
  get rangeQuery => LocalTimeRangeQuery(
    ref: DateTime.now(),
    dayOffset: dayStart,
    unit: GroupFreq.day,
    overlapMode: OverlapMode.fullyInside,
  );

  @override
  Future<void> load() async {
    // load events
    final evts = await db.evts.filteredLocalTime(range: rangeQuery.toDbRange());
    // NOTE: this assumes the type cache is filled!
    refreshSummary(evts);

    notifyListeners();
  }
}
