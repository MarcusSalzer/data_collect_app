import 'package:data_collector_app/utility/data_util.dart';
import 'package:data_collector_app/utility/input_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputFormVertical extends StatefulWidget {
  const InputFormVertical({super.key});

  @override
  State<InputFormVertical> createState() => _InputFormVerticalState();
}

class _InputFormVerticalState extends State<InputFormVertical> {
  final _formKey = GlobalKey<FormState>();
  late final DataModel _model;
  late final Dataset _dataset;

  late final int _nFields;
  late final List<TextEditingController> _controllers;

  // For focusing first field on submit
  final FocusNode _firstFieldFocus = FocusNode();

  final List<Widget> _formFields = [];

  @override
  void initState() {
    super.initState();

    // only get dataset once (probably works)
    _model = Provider.of<DataModel>(context, listen: false);
    _dataset = _model.currentDataset;
    _nFields = _dataset.schema.length;
    _controllers = List.generate(_nFields, (_) => TextEditingController());

    // generate fields
    for (var (index, MapEntry(key: name, value: dtype))
        in _dataset.schema.entries.indexed) {
      _formFields.add(Padding(
        // ensure space for form validation messages
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: "$name ($dtype)",
          ),
          controller: _controllers[index],
          validator: (value) => validateField(value ?? "", dtype),
          onFieldSubmitted: (value) {
            _addSample();
          },
          focusNode: index == 0 ? _firstFieldFocus : null, // only for first
        ),
      ));
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    _firstFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: _formFields,
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton.icon(
              onPressed: () {
                _addSample();
              },
              label: const Text("Add"),
              icon: const Icon(Icons.add),
            )
          ],
        ),
      ),
    );
  }

  void _addSample() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // get text inputs
    final texts = _controllers.map((e) => e.text).toList();

    // TODO: bug: 00:00
    // var timestamp = (_addDate ?? DateTime.now())
    //     .copyWith(hour: _addTime?.hour, minute: _addTime?.minute);

    final timestamp = DateTime.now();
    _model.addSample(timestamp, texts);

    // clear form
    for (var c in _controllers) {
      c.clear();
    }

    // focus first field
    _firstFieldFocus.requestFocus();

    // clear add-timestamps
    // setState(() {
    //   _addDate = null;
    //   _addTime = null;
    // });
  }
}
