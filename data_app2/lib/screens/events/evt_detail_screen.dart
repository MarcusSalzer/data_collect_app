import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/view_models/evt_detail_vm.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/local_datetime.dart';
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
      create: (context) {
        final app = context.read<AppState>();
        return EvtDetailVm(
          evt,
          app.db.evts,
          app.evtTypeManager,
        );
      },
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

class EventEditForm extends StatelessWidget {
  const EventEditForm({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EvtDetailVm>(context, listen: false);
    final app = Provider.of<AppState>(context, listen: false);
    final locMan = context.read<LocationManager>();

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
        (
          Text("Location"),
          GenericAutocomplete<LocationRec>(
            options: locMan.all,
            initialValue: null,
            nameOf: (e) => e.name,
            onSelected: vm.changeLocation,
            optionBuilder: (context, e) => ListTile(
              title: Text(e.name),
            ),
            searchMode: app.textSearchMode,
          ),
        ),
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
          child: Text(Fmt.date(ldt?.asLocal)),
        ),
        TextButton(
          onPressed: () async {
            final ogLocal = ldt?.asLocal ?? DateTime.now();
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: ogLocal.hour, minute: ogLocal.minute),
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
    final locMan = context.watch<LocationManager>();
    final location = locMan.fromId(evt.locationId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subtitle("Details"),
        _buildInfoRow('ID', evt.id.toString()),
        _buildInfoRow('Type', evtType.toString()),
        _buildInfoRow('Location', location?.name ?? "N/A"),
        _buildInfoRow('Duration', Fmt.durationHmVerbose(evt.duration)),
        _subtitle("Start"),
        _buildInfoRow('Local', Fmt.dtSecond(evt.start?.asLocal)),
        _buildInfoRow('UTC', Fmt.dtSecond(evt.start?.asUtc)),
        _buildInfoRow('TZ offset', Fmt.durationHmVerbose(evt.start?.offset)),
        _subtitle("End"),
        _buildInfoRow('Local', Fmt.dtSecond(evt.end?.asLocal)),
        _buildInfoRow('UTC', Fmt.dtSecond(evt.end?.asUtc)),
        _buildInfoRow('TZ offset', Fmt.durationHmVerbose(evt.end?.offset)),
      ],
    );
  }
}
