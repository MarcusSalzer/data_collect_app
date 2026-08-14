import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/screens/events/evt_detail_screen.dart';
import 'package:data_app2/screens/evt_picker_screen.dart';
import 'package:data_app2/view_models/blob_edit_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlobEditScreen extends StatelessWidget {
  final BlobSchemaRec schema;
  final UserBlobRec? existing;
  const BlobEditScreen(this.schema, this.existing, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserBlobEditVm>(
      create: (context) {
        final db = context.read<AppState>().db;
        return UserBlobEditVm(existing, schema, db.blobs, db.userEnums, db.userEnumValues, db.evts)..load();
      },
      builder: (context, child) {
        final vm = context.watch<UserBlobEditVm>();
        return EditScaffoldForVm(
          vm: vm,
          title: vm.schema.name,
          body: Consumer<UserBlobEditVm>(
            builder: (context, vm, _) {
              final thm = Theme.of(context);
              final fieldInputs = <Widget>[
                for (final entry in vm.schema.fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FieldInput(
                      name: entry.key,
                      spec: entry.value,
                      vm: vm,
                    ),
                  ),
              ];

              // Add event field if needed
              final evt = vm.linkedEvent;
              if (vm.schema.evtLink case EvtLinkSpec link) {
                fieldInputs.add(
                  Container(
                    padding: EdgeInsets.all(4),
                    color: thm.colorScheme.primaryContainer,
                    child: Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Linked Event",
                          style: thm.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        (evt == null) ? Center(child: Text("N/A")) : Text(evt.toString()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.edit),
                              label: Text("edit"),
                              onPressed: evt == null
                                  ? null
                                  : () {
                                      // show event, but no blobs here
                                      Navigator.of(
                                        context,
                                      ).push(MaterialPageRoute(builder: (context) => EvtDetailScreen(evt, null))).then((
                                        _,
                                      ) {
                                        // reload after possible changes
                                        vm.load();
                                      });
                                    },
                            ),
                            TextButton.icon(
                              icon: Icon(Icons.swap_horiz),
                              label: Text("swap"),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EvtPickerScreen(link.typIds, evt, onSelect: vm.setEvent),
                                  ),
                                );
                              },
                            ),
                            TextButton.icon(
                              icon: Icon(Icons.close),
                              label: Text("unset"),
                              onPressed: evt == null
                                  ? null
                                  : () {
                                      vm.unsetEvent();
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: fieldInputs,
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () async {
                  if (vm.validate()) {
                    await vm.save();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                child: Text(vm.hasStored ? 'Update' : 'Save'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FieldInput extends StatelessWidget {
  const _FieldInput({required this.name, required this.spec, required this.vm});
  final String name;
  final BlobFieldSpec spec;
  final UserBlobEditVm vm;

  @override
  Widget build(BuildContext context) {
    final error = vm.errorFor(name);
    final label = spec.nullable ? name : '$name *';

    return switch (spec.type) {
      DInt() => TextFormField(
        initialValue: (vm.rawValue(name) as int?)?.toString() ?? '',
        decoration: InputDecoration(labelText: label, errorText: error),
        keyboardType: TextInputType.number,
        onChanged: (text) => vm.setValue(name, int.tryParse(text)),
      ),
      DDecimal() => TextFormField(
        initialValue: (vm.rawValue(name) as num?)?.toString() ?? '',
        decoration: InputDecoration(labelText: label, errorText: error),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (text) => vm.setValue(name, double.tryParse(text)),
      ),
      DText() => TextFormField(
        initialValue: vm.rawValue(name).toString(),
        decoration: InputDecoration(labelText: label, errorText: error),
        onChanged: (text) => vm.setValue(name, double.tryParse(text)),
      ),
      DBool() => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: error != null ? Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
        value: vm.rawValue(name) as bool? ?? false,
        onChanged: (v) => vm.setValue(name, v),
      ),
      // DTimestamp() => _TimestampInput(
      //   label: label,
      //   error: error,
      //   millis: vm.rawValue(name) as int?,
      //   onChanged: (millis) => vm.setValue(name, millis),
      // ),
      DEnum(:final group) => _EnumInput(
        name: name,
        label: label,
        error: error,
        group: group,
      ),
      // TODO: Handle this case.
      DDuration() => throw UnimplementedError(),
      // TODO: Handle this case.
      // DTuple() => throw UnimplementedError(),
      DArray() => throw UnimplementedError(),
    };
  }
}

class _EnumInput extends StatelessWidget {
  final String name;
  final String label;
  final String? error;
  final String group;

  const _EnumInput({required this.name, required this.label, this.error, required this.group});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserBlobEditVm>();
    final enumValues = vm.enumGroupValues;

    if (enumValues == null) {
      return Text("Loading...");
    }
    final groupValues = enumValues[group];

    if (groupValues == null) {
      return Text("'$group' has no values");
    }

    return DropdownButtonFormField<String>(
      initialValue: vm.rawValue(name) as String?,
      decoration: InputDecoration(labelText: label, errorText: error),
      items: [for (final v in groupValues) DropdownMenuItem(value: v, child: Text(v))],
      onChanged: (v) => vm.setValue(name, v),
    );
  }
}

class _TimestampInput extends StatelessWidget {
  const _TimestampInput({
    required this.label,
    required this.error,
    required this.millis,
    required this.onChanged,
  });
  final String label;
  final String? error;
  final int? millis;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = millis != null ? DateTime.fromMillisecondsSinceEpoch(millis!) : null;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
        );
        if (time == null) return;
        final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        onChanged(combined.millisecondsSinceEpoch);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, errorText: error),
        child: Text(current?.toString() ?? 'Tap to select'),
      ),
    );
  }
}
