import 'package:data_app2/app_state.dart';
import 'package:data_app2/blob_for_evt_cache.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/repos/evt_repo.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/widgets/evt_blob_summary.dart';
import 'package:data_app2/widgets/evt_sub_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// ViewModel for selecting an event.
class EvtPickerVm extends ChangeNotifier {
  final EvtRepo repo;
  // needed prefs
  final int dayStartsH;
  final Set<int> filterTypeIds;

  EvtPickerVm(this.repo, this.filterTypeIds, this.selected, {required this.dayStartsH})
    : _date = DateTime.now().startOfDay;

  // --- State ---
  List<EvtRec>? events;
  DateTime _date;
  EvtRec? selected;

  DateTime get date => _date;

  /// Move to a new date and start loading events.
  void setDate(DateTime? dt) {
    if (dt == null) {
      return; // no change
    }
    _date = dt.startOfDay;
    // clear events
    events = null;
    notifyListeners();
    // start relading
    load();
  }

  void load() async {
    // create a query to apply on stored local timestamps.
    final q = LocalTimeRangeQuery(
      ref: _date,
      dayOffset: Duration(hours: dayStartsH),
      unit: GroupFreq.day,
      overlapMode: OverlapMode.overlapping,
    );
    await Future.delayed(Duration(milliseconds: 300));

    /// Get all events of matching type and time range
    events = (await repo.filteredLocalTime(q.toDbRange(), typeIds: filterTypeIds)).toList().reversed.toList();

    notifyListeners();
  }
}

/// Screen for selecting an existing event.
/// Uses a callback to return the selected event record.
class EvtPickerScreen extends StatelessWidget {
  final Set<int> typeIds;
  final void Function(EvtRec) onSelect;
  final EvtRec? current;
  const EvtPickerScreen(this.typeIds, this.current, {required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);
    // to resolve event types & locations
    final typMan = context.read<AppState>().evtTypeManager;
    final locMan = context.read<AppState>().locationManager;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pick event"),
      ),
      body: ChangeNotifierProvider<EvtPickerVm>(
        create: (context) {
          final db = context.read<AppState>().db;

          return EvtPickerVm(db.evts, typeIds, current, dayStartsH: prefs.dayStartsH)..load();
        },
        builder: (context, child) {
          final vm = context.watch<EvtPickerVm>();
          final dateEvts = vm.events;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Date"),
                    TextButton(
                      onPressed: () async {
                        vm.setDate(
                          await showDatePicker(
                            context: context,
                            firstDate: DateTime(1970),
                            lastDate: DateTime(2222),
                          ),
                        );
                      },
                      child: Text(Fmt.date(vm._date)),
                    ),
                  ],
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (dateEvts == null) {
                        return Center(child: Text("Loading..."));
                      }
                      if (dateEvts.isEmpty) {
                        return Center(child: Text("No matching events."));
                      }
                      return ChangeNotifierProvider<BlobForEvtCache>(
                        create: (context) => BlobForEvtCache(context.read<AppState>().db.blobs, () => dateEvts)..load(),
                        builder: (context, child) {
                          final blobVm = context.watch<BlobForEvtCache>();

                          return ListView.builder(
                            itemCount: dateEvts.length,
                            itemBuilder: (context, index) {
                              final evt = dateEvts[index];
                              final et = typMan.typeFromId(evt.typeId);

                              // If event type missing from cache
                              if (et == null) {
                                return ListTile(
                                  title: Text(
                                    "Error: event type not found",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  subtitle: Text(evt.toString()),
                                );
                              }

                              final blobs = blobVm.forEvt(evt.id);

                              return ListTile(
                                selected: evt.id == vm.selected?.id,
                                title: Row(
                                  spacing: 8,
                                  children: [
                                    CircleAvatar(
                                      radius: 5,
                                      backgroundColor: typMan.colorFor(et, prefs.colorSpread),
                                    ),
                                    Text(et.name),
                                  ],
                                ),
                                subtitle: EvtSubTitle(evt, locMan.fromId(evt.locationId)),
                                trailing: (blobs == null) ? null : EvtBlobSummaryIndicator(blobs),
                                onTap: () {
                                  // Select and go back
                                  vm.selected = evt;
                                  onSelect(evt);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
