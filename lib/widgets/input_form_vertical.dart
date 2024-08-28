import 'package:data_collector_app/data_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputFormVertical extends StatefulWidget {
  const InputFormVertical({super.key});

  @override
  State<InputFormVertical> createState() => _InputFormVerticalState();
}

class _InputFormVerticalState extends State<InputFormVertical> {
  final GlobalKey _formKey = GlobalKey<FormState>();
  late final Dataset _dataset;

  late final int _nFields;
  late final List<TextEditingController> _controllers;

  // For focusing first field on submit
  final FocusNode _firstFieldFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // only get dataset once (probably works)
    _dataset = Provider.of<DataModel>(context, listen: false).currentDataset;
    _nFields = _dataset.schema.length;
    _controllers = List.generate(_nFields, (_) => TextEditingController());
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
    List<Widget> formFields = [
      for (var (index, field) in _dataset.schema.entries.indexed)
        Expanded(
          child: Padding(
            // ensure space for form validation messages
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: "${field.key} (${field.value})",
              ),
              controller: _controllers[index],
              // validator: (value) => _validateField(value ?? "", _dtypes[i]),
              onFieldSubmitted: (value) {
                print("TODO");
              },
              focusNode: index == 0 ? _firstFieldFocus : null, // only for first
            ),
          ),
        )
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Center(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:formFields,
            ),
          ),
        ),
      ),
    );
  }
}
