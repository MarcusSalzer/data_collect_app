import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ColorSpreadScreen extends StatefulWidget {
  final AppState app;
  const ColorSpreadScreen(this.app, {super.key});

  @override
  State<ColorSpreadScreen> createState() {
    return _ColorSpreadScreenState();
  }
}

class _ColorSpreadScreenState extends State<ColorSpreadScreen> {
  bool _isDirty = false;
  late double value;
  @override
  void initState() {
    super.initState();
    value = widget.app.prefs.colorSpread;
  }

  /// Only setState if isDirty changes
  void _onChange(double v) {
    value = v;
    if (_isDirty && v == widget.app.prefs.colorSpread) {
      setState(() => _isDirty = false);
    } else if (!_isDirty && v != widget.app.prefs.colorSpread) {
      setState(() => _isDirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditScaffoldSimple(
      title: "Color spread",
      isDirty: _isDirty,
      saveAction: () async {
        await widget.app.updatePrefs(widget.app.prefs.copyWith(colorSpread: value));
        return true;
      },
      body: ColorSpreadPicker(initValue: widget.app.prefs.colorSpread, onEdited: _onChange),
    );
  }
}

class ColorSpreadPicker extends StatefulWidget {
  const ColorSpreadPicker({super.key, required this.initValue, required this.onEdited});
  final ValueChanged<double> onEdited;
  final double initValue;

  @override
  State<ColorSpreadPicker> createState() => _ColorSpreadPickerState();
}

class _ColorSpreadPickerState extends State<ColorSpreadPicker> {
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
        Row(
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
      ],
    );
  }
}
