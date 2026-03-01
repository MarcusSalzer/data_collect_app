import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/view_models/evt_create_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EvtCreateMenu extends StatelessWidget {
  const EvtCreateMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(spacing: 32, children: [_EvtInput(), _SuggestionButtons()]),
    );
  }
}

/// Create events using the VM
class _EvtInput extends StatelessWidget {
  final fieldHeight = 60.0; // fixed to prevent Layout shift
  final timeWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EvtCreateVm>();
    if (!vm.isReady) {
      return SizedBox(
        height: 2 * fieldHeight,
        child: Center(child: Text("Loading...")),
      );
    }

    final cur = vm.current;
    final currentType = vm.currentType;
    final currentField = (cur == null)
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: timeWidth, child: Text(Fmt.time(DateTime.now()))),
              Expanded(
                child: Text("No current event", style: TextStyle(color: Colors.grey)),
              ),
              // Inactive button
              TextButton.icon(onPressed: null, label: Text("stop"), icon: Icon(Icons.stop)),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: timeWidth, child: Text(Fmt.time(cur.start?.asUtcWithLocalValue))),
              Expanded(child: Text(currentType?.name ?? "unknown")),
              TextButton.icon(onPressed: vm.stopCurrent, label: Text("stop"), icon: Icon(Icons.stop)),
            ],
          );

    return Column(
      children: [
        SizedBox(height: fieldHeight, child: currentField),
        SizedBox(height: fieldHeight, child: _QuickStartRow(timeWidth)),
      ],
    );
  }
}

class _QuickStartRow extends StatefulWidget {
  final double leftWidth;
  const _QuickStartRow(this.leftWidth);

  @override
  State<_QuickStartRow> createState() => _QuickStartRowState();
}

class _QuickStartRowState extends State<_QuickStartRow> {
  final _nameTec = TextEditingController();

  @override
  void dispose() {
    _nameTec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EvtCreateVm>();

    return Row(
      children: [
        SizedBox(width: widget.leftWidth),
        Expanded(
          child: TextField(
            controller: _nameTec,
            decoration: const InputDecoration(label: Text("start"), border: UnderlineInputBorder()),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameTec,
          builder: (context, value, _) {
            final canStart = value.text.trim().isNotEmpty;

            return TextButton.icon(
              onPressed: canStart
                  ? () {
                      vm.addEventByName(_nameTec.text.trim());
                      _nameTec.clear();
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text("start"),
            );
          },
        ),
      ],
    );
  }
}

class _SuggestionButtons extends StatelessWidget {
  const _SuggestionButtons();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EvtCreateVm>();
    final colorSpread = context.select<AppState, double>((a) => a.prefs.colorSpread);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: vm.suggestions.map((et) {
        final name = et.name;
        return ActionChip(
          label: Text(name),
          onPressed: () {
            // add event
            vm.addEventByTypeId(et.id);
          },
          shape: RoundedRectangleBorder(
            side: BorderSide(color: vm.colorFor(et, colorSpread)),
            borderRadius: BorderRadiusGeometry.all(Radius.circular(6)),
          ),
        );
      }).toList(),
    );
  }
}
