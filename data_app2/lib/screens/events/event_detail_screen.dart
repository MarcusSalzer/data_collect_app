import 'package:data_app2/app_state.dart';
import 'package:data_app2/dialogs/show_confirm_save_back_dialog.dart';
import 'package:data_app2/event_detail_view_model.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventDetailScreen extends StatelessWidget {
  final EvtRec evt;

  const EventDetailScreen(this.evt, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EventDetailViewModel>(
      create: (context) {
        final app = Provider.of<AppState>(context, listen: false);
        return EventDetailViewModel(evt, app);
      },
      child: Consumer<EventDetailViewModel>(
        builder: (context, vm, child) => PopScope(
          canPop: !vm.isDirty,
          onPopInvokedWithResult: (didPop, Object? res) async {
            if (!didPop) {
              showConfirmSaveBackDialog(context, saveAction: () async {
                try {
                  await vm.save();
                  if (context.mounted) simpleSnack(context, "Saved!");
                  return vm.evt;
                } catch (e) {
                  if (context.mounted) {
                    simpleSnack(context, e.toString(), color: Colors.red);
                  }
                }
                return null;
              });
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Event ${vm.evt.id}${vm.isDirty ? " *" : ""}"),
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: vm.evtType?.color.inContext(context),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmDialog(
                        title: "Delete event?",
                        action: () async {
                          final didDelete = await vm.delete();
                          if (context.mounted) {
                            if (didDelete) {
                              simpleSnack(context, "Deleted event ${evt.id}");
                            } else {
                              simpleSnack(context, "Failed to delete event",
                                  color: Colors.red);
                            }
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_forever),
                )
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
                                Navigator.of(context).pop(vm.evt);
                                simpleSnack(context, "Saved!");
                              }
                            } catch (e) {
                              if (context.mounted) {
                                simpleSnack(context, e.toString(),
                                    color: Colors.red);
                              }
                            }
                          },
                          child: Text("Save & exit")),
                    ),
                  SizedBox(height: 16),
                  EventDetailDisplay(vm.evt, vm.evtType),
                ],
              ),
            )),
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
    final vm = Provider.of<EventDetailViewModel>(context, listen: false);
    return TwoColumns(
      flex: (1, 3),
      rows: [
        (
          Text("Type"),
          TypeSelector(
              options: vm.allTypes,
              startOpt: vm.evtType,
              onSelected: (v) {
                final newTypeId = v.id;
                // only allow setting persisted (has-id) types
                if (newTypeId != null) {
                  vm.changeType(newTypeId);
                }
              })
        ),
        (Text("Start"), DTPickerPair(vm.evt.start, vm.changeStartLocalTZ)),
        (Text("End"), DTPickerPair(vm.evt.end, vm.changeEndLocalTZ)),
      ],
    );
  }
}

class DTPickerPair extends StatelessWidget {
  final LocalDateTime? ldt;

  final Function(DateTime) onChange;
  const DTPickerPair(
    this.ldt,
    this.onChange, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
            onPressed: () async {
              final dt = await showDatePicker(
                context: context,
                firstDate: DateTime(1970),
                lastDate: DateTime(2222),
              );
              if (dt != null) {
                final ogLocal = ldt?.asLocal ?? DateTime.now();
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
            child: Text(Fmt.date(ldt?.asLocal))),
        TextButton(
          onPressed: () async {
            final ogLocal = ldt?.asLocal ?? DateTime.now();
            final t = await showTimePicker(
              context: context,
              initialTime:
                  TimeOfDay(hour: ogLocal.hour, minute: ogLocal.minute),
            );
            if (t != null) {
              final ogLocal = ldt?.asLocal ?? DateTime.now();

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
          child: Text(Fmt.time(ldt?.asLocal)),
        ),
      ],
    );
  }
}

class TypeSelector extends StatelessWidget {
  final List<EvtTypeRec> options;
  final void Function(EvtTypeRec) onSelected;

  final EvtTypeRec? startOpt;

  const TypeSelector({
    super.key,
    required this.options,
    required this.startOpt,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<EvtTypeRec>(
      // how we filter the options
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        return options.where((o) => o.name
            .toLowerCase()
            .startsWith(textEditingValue.text.toLowerCase()));
      },
      // what happens when the user selects
      onSelected: onSelected,
      // how to turn an option into text in the input field
      displayStringForOption: (EvtTypeRec option) => option.name,
      // how each suggestion is rendered in the dropdown list
      optionsViewBuilder:
          (context, onSelected, Iterable<EvtTypeRec> filteredOptions) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 200, // scrollable area
              child: ListView.builder(
                itemCount: filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = filteredOptions.elementAt(index);
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 5,
                      backgroundColor: option.color.inContext(context),
                    ),
                    title: Text(option.name),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      // customizing the input field
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.text = startOpt?.name ?? "";

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Type',
            border: OutlineInputBorder(),
          ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
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
          Expanded(
            flex: 2,
            child: Text(
              title,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontFamily: "monospace"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        t,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subtitle("Details"),
        _buildInfoRow('ID', evt.id?.toString() ?? 'N/A'),
        _buildInfoRow('Type', evtType.toString()),
        _buildInfoRow('Duration', Fmt.durationHM(evt.duration)),
        _subtitle("Start"),
        _buildInfoRow('Local', Fmt.dtSecond(evt.start?.asLocal)),
        _buildInfoRow('UTC', Fmt.dtSecond(evt.start?.asUtc)),
        _buildInfoRow('TZ offset', Fmt.durationHM(evt.start?.offset)),
        _subtitle("End"),
        _buildInfoRow('Local', Fmt.dtSecond(evt.end?.asLocal)),
        _buildInfoRow('UTC', Fmt.dtSecond(evt.end?.asUtc)),
        _buildInfoRow('TZ offset', Fmt.durationHM(evt.end?.offset)),
      ],
    );
  }
}
