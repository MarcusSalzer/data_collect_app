import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/view_models/blob_edit_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlobEditScreen extends StatelessWidget {
  const BlobEditScreen({super.key, required this.vm});
  final UserBlobEditVm vm;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: vm,
      child: Scaffold(
        appBar: AppBar(title: Text(vm.schema.name)),
        body: Consumer<UserBlobEditVm>(
          builder: (context, vm, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in vm.schema.fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FieldInput(
                    name: entry.key,
                    spec: entry.value,
                    vm: vm,
                  ),
                ),
            ],
          ),
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
      ),
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
      DBool() => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: error != null ? Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
        value: vm.rawValue(name) as bool? ?? false,
        onChanged: (v) => vm.setValue(name, v),
      ),
      DTimestamp() => _TimestampInput(
        label: label,
        error: error,
        millis: vm.rawValue(name) as int?,
        onChanged: (millis) => vm.setValue(name, millis),
      ),
      DEnum(:final group) => DropdownButtonFormField<String>(
        initialValue: vm.rawValue(name) as String?,
        decoration: InputDecoration(labelText: label, errorText: error),
        items: [
          for (final v in vm.enumGroupValues[group] ?? const <String>[]) DropdownMenuItem(value: v, child: Text(v)),
        ],
        onChanged: (v) => vm.setValue(name, v),
      ),
      // TODO: Handle this case.
      DDuration() => throw UnimplementedError(),
      // TODO: Handle this case.
      DTuple() => throw UnimplementedError(),
    };
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
