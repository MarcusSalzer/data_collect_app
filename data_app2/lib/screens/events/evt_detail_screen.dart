import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/dialogs/show_confirm_save_back_dialog.dart';
import 'package:data_app2/view_models/evt_detail_vm.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:data_app2/widgets/generic_autocomplete.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EvtDetailScreen extends StatelessWidget {
  final EvtRec evt;

  const EvtDetailScreen(this.evt, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EvtDetailVm>(
      create: (context) => EvtDetailVm(evt, context.read<AppState>()),
      child: Consumer<EvtDetailVm>(
        builder: (context, vm, child) => EditScaffoldForVm<EvtRec>(
          title: "Event",
          body: SingleChildScrollView(
            child: Column(
              spacing: 12,
              children: [EventEditForm(), if (vm.stored case EvtRec st) EventDetailDisplay(st, vm.evtType)],
            ),
          ),
          vm: vm,
        ),
      ),
    );
  }
}

@Deprecated("New uses edit scaffold")
class EvtDetailScreenOld extends StatelessWidget {
  final EvtRec evt;

  const EvtDetailScreenOld(this.evt, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EvtDetailVm>(
      create: (context) {
        final app = Provider.of<AppState>(context, listen: false);
        return EvtDetailVm(evt, app);
      },
      child: Consumer<EvtDetailVm>(
        builder: (context, vm, child) => PopScope(
          canPop: !vm.isDirty,
          onPopInvokedWithResult: (didPop, Object? res) async {
            if (!didPop) {
              showConfirmSaveBackDialog(
                context,
                saveAction: () async {
                  try {
                    await vm.save();
                    if (context.mounted) simpleSnack(context, "Saved!");
                  } catch (e) {
                    if (context.mounted) {
                      simpleSnack(context, e.toString(), color: Colors.red);
                    }
                  }
                  return null;
                },
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Event ${vm.stored?.id}${vm.isDirty ? " *" : ""}"),
                  CircleAvatar(radius: 8, backgroundColor: vm.color),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text("Are you sure?"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton.icon(
                              onPressed: () async {
                                final didDelete = await vm.delete();
                                if (context.mounted) {
                                  if (didDelete) {
                                    simpleSnack(context, "Deleted event ${evt.id}");
                                  } else {
                                    simpleSnack(context, "Failed to delete event", color: Colors.red);
                                  }
                                  // close dialog
                                  Navigator.of(context).pop();
                                  // leave details page
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: Icon(Icons.dangerous_outlined),
                              label: Text("delete permanently"),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_forever),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    EventEditForm(),
                    if (vm.isDirty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: TextButton(
                          onPressed: () async {
                            try {
                              await vm.save();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                simpleSnack(context, "Saved!");
                              }
                            } catch (e) {
                              if (context.mounted) {
                                simpleSnack(context, e.toString(), color: Colors.red);
                              }
                            }
                          },
                          child: Text("Save & exit"),
                        ),
                      ),
                    SizedBox(height: 16),
                    if (vm.stored case EvtRec st) EventDetailDisplay(st, vm.evtType),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventEditForm extends StatelessWidget {
  const EventEditForm({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EvtDetailVm>(context, listen: false);
    final app = Provider.of<AppState>(context, listen: false);

    return TwoColumns(
      flex: (1, 3),
      rows: [
        (
          Text("Type"),
          GenericAutocomplete<EvtTypeRec>(
            options: vm.allTypes,
            initialValue: vm.evtType,
            nameOf: (e) => e.name,
            onSelected: (v) {
              vm.changeType(v.id);
            },
            optionBuilder: (context, e) => ListTile(
              leading: CircleAvatar(radius: 5, backgroundColor: app.colorFor(e)),
              title: Text(e.name),
            ),
            searchMode: app.textSearchMode,
          ),
        ),
        (Text("Start"), DTPickerPair(vm.draft.start, vm.changeStartLocalTZ)),
        (Text("End"), DTPickerPair(vm.draft.end, vm.changeEndLocalTZ)),
      ],
    );
  }
}

/// Textbuttons displaying date and time.
/// Click to show date/time-picker.
class DTPickerPair extends StatelessWidget {
  final LocalDateTime? ldt;

  final Function(DateTime) onChange;
  const DTPickerPair(this.ldt, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () async {
            final dt = await showDatePicker(context: context, firstDate: DateTime(1970), lastDate: DateTime(2222));
            if (dt != null) {
              final ogLocal = ldt?.asUtcWithLocalValue ?? DateTime.now();
              final newLocal = DateTime(
                // Update Year Month Day
                dt.year,
                dt.month,
                dt.day,
                // keep original time (or now)
                ogLocal.hour,
                ogLocal.minute,
                ogLocal.second,
                ogLocal.millisecond,
              );
              onChange(newLocal);
            }
          },
          child: Text(Fmt.date(ldt?.asUtcWithLocalValue)),
        ),
        TextButton(
          onPressed: () async {
            final ogLocal = ldt?.asUtcWithLocalValue ?? DateTime.now();
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: ogLocal.hour, minute: ogLocal.minute),
            );
            if (t != null) {
              final ogLocal = ldt?.asUtcWithLocalValue ?? DateTime.now();

              final newLocal = DateTime(
                // Keep original Year Month Day (or now)
                ogLocal.year,
                ogLocal.month,
                ogLocal.day,
                // Update time
                t.hour,
                t.minute,
              );
              onChange(newLocal);
            }
          },
          child: Text(Fmt.time(ldt?.asUtcWithLocalValue)),
        ),
      ],
    );
  }
}

class EventDetailDisplay extends StatelessWidget {
  final EvtRec evt;
  final EvtTypeRec? evtType;

  const EventDetailDisplay(this.evt, this.evtType, {super.key});

  // A helper method to create a row for a single data pair
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(title)),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(fontFamily: "monospace")),
          ),
        ],
      ),
    );
  }

  Widget _subtitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(t, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subtitle("Details"),
        _buildInfoRow('ID', evt.id.toString()),
        _buildInfoRow('Type', evtType.toString()),
        _buildInfoRow('Duration', Fmt.durationHmVerbose(evt.duration)),
        _subtitle("Start"),
        _buildInfoRow('Local', Fmt.dtSecond(evt.start?.asUtcWithLocalValue)),
        _buildInfoRow('UTC', Fmt.dtSecond(evt.start?.asUtc)),
        _buildInfoRow('TZ offset', Fmt.durationHmVerbose(evt.start?.offset)),
        _subtitle("End"),
        _buildInfoRow('Local', Fmt.dtSecond(evt.end?.asUtcWithLocalValue)),
        _buildInfoRow('UTC', Fmt.dtSecond(evt.end?.asUtc)),
        _buildInfoRow('TZ offset', Fmt.durationHmVerbose(evt.end?.offset)),
      ],
    );
  }
}
