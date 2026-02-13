import 'package:data_app2/util/colors.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ColorSpreadScreen extends StatefulWidget {
  final double initVal;
  final Future<bool> Function(double) saveAction;
  const ColorSpreadScreen({required this.initVal, required this.saveAction, super.key});

  @override
  State<ColorSpreadScreen> createState() {
    return _ColorSpreadScreenState();
  }
}

class _ColorSpreadScreenState extends State<ColorSpreadScreen> {
  bool _isDirty = false;
  late double value; // updates on slider
  late double savedVal; // updates on save
  @override
  void initState() {
    super.initState();
    value = widget.initVal;
    savedVal = widget.initVal;
  }

  /// Only setState if isDirty changes
  void _onChange(double v) {
    value = v;
    if (_isDirty && v == savedVal) {
      setState(() => _isDirty = false);
    } else if (!_isDirty && v != savedVal) {
      setState(() => _isDirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditScaffoldSimple(
      title: "Color spread",
      isDirty: _isDirty,
      saveAction: () async {
        final ok = await widget.saveAction(value);
        if (ok) {
          setState(() => _isDirty = false);
        }
        return ok;
      },
      body: _ColorSpreadPicker(initValue: value, onEdited: _onChange),
    );
  }
}

class _ColorSpreadPicker extends StatefulWidget {
  const _ColorSpreadPicker({required this.initValue, required this.onEdited});
  final ValueChanged<double> onEdited;
  final double initValue;

  @override
  State<_ColorSpreadPicker> createState() => _ColorSpreadPickerState();
}

class _ColorSpreadPickerState extends State<_ColorSpreadPicker> {
  late double _spreadFactor;
  final nVariants = 5; // Number of color variants to display

  @override
  void initState() {
    super.initState();
    _spreadFactor = widget.initValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,

            children: ColorEngine.defaults.values
                .map(
                  (color) => Expanded(
                    child: Row(
                      children: List.generate(
                        nVariants,
                        (i) => Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorEngine.spread(color, i, nVariants, _spreadFactor),
                              borderRadius: BorderRadius.all(Radius.circular(2)),
                            ),
                            margin: EdgeInsets.all(2),
                            child: Center(child: Text(ColorEngine.norm(i, nVariants).toString())),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(NumberFormat.decimalPercentPattern(decimalDigits: 0).format(_spreadFactor)),
              ),
              Expanded(
                child: Slider(
                  divisions: 10,
                  value: _spreadFactor,
                  onChanged: (value) {
                    setState(() {
                      _spreadFactor = value;
                      widget.onEdited(value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
