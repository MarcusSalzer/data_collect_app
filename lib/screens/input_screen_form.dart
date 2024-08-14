import 'dart:async';

import 'package:data_collector_app/data_provider_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputScreenForm extends StatefulWidget {
  final Map<String, dynamic> dataset;
  const InputScreenForm({super.key, required this.dataset});

  @override
  State<InputScreenForm> createState() => _InputScreenFormState();
}

class _InputScreenFormState extends State<InputScreenForm> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _addSample(String sample, DateTime timestamp) async {
    final number = num.tryParse(sample);
    if (number != null) {
      setState(() {});
      print("TODO save sample at $timestamp");
    }
  }

  void _saveAndReturn(BuildContext context) async {
    print("TODO: save here!");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.dataset["name"]),
          actions: [
            ElevatedButton.icon(
                onPressed: () {
                  _saveAndReturn(context);
                },
                icon: const Icon(Icons.save),
                label: const Text("Save"))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                color: const Color.fromARGB(255, 236, 222, 222),
                child: InputForm(
                  dataset: widget.dataset,
                ),
              ),
              const HistoryList(),
            ],
          ),
        ));
  }
}

class InputForm extends StatefulWidget {
  final Map<String, dynamic> dataset;
  const InputForm({super.key, required this.dataset});

  @override
  State<InputForm> createState() => _InputFormState();
}

class _InputFormState extends State<InputForm> {
  final _formKey = GlobalKey<FormState>();
  final bool _disableAdd = false;
  // TODO MAKE sure to disable ad if data not loaded yet

  late final List<String> _fieldNames;
  late final List<String> _dtypes;
  late final int _nFields;
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();

    _fieldNames = List<String>.from(widget.dataset["schema"].keys);
    _dtypes = List<String>.from(widget.dataset["schema"].values);
    _nFields = _fieldNames.length;
    _controllers = List.generate(_nFields, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Validate an input field based on its [dtype].
  String? _validateField(String text, String dtype, {bool allowEmpty = true}) {
    text = text.trim();
    if (text.isEmpty) {
      if (allowEmpty) {
        return null;
      } else {
        return "Please enter a value";
      }
    }

    switch (dtype) {
      case "numeric":
        if (num.tryParse(text) == null) {
          return "Invalid number";
        }
        break;
      case "datetime":
        if (DateTime.tryParse(text) == null) {
          return "Cannot parse DateTime";
        }
        break;
    }
    return null;
  }

  void _addSample() {
    if (!_formKey.currentState!.validate()) {
      print("bad form");
      return;
    } else {
      print("OK form");
    }

    final texts = _controllers.map((e) => e.text).toList();
    print(texts);
    Provider.of<DataProviderRow>(context, listen: false).addSample(texts);

    // clear form
    for (var c in _controllers) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> formFields = [
      for (var i = 0; i < _nFields; i++)
        Expanded(
          child: Padding(
            // ensure space for form validation messages
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: "${_fieldNames[i]} (${_dtypes[i]})",
              ),
              controller: _controllers[i],
              validator: (value) => _validateField(value ?? "", _dtypes[i]),
            ),
          ),
        )
    ];

    return Form(
      key: _formKey,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () {},
              label: const Text("Today"),
              icon: const Icon(Icons.calendar_month),
            ),
            TextButton.icon(
              onPressed: () {},
              label: const Text("Now"),
              icon: const Icon(Icons.timelapse),
            ),
            ...formFields,
            const VerticalDivider(
              width: 3,
              thickness: 1,
              indent: 1,
              endIndent: 1,
              color: Colors.grey,
            ),
            SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                onPressed: _disableAdd
                    ? null
                    : () {
                        _addSample();
                      },
                label: const Text("Add"),
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<DataProviderRow>(
        builder: (context, dataProvider, child) {
          if (dataProvider.data == null) {
            return const Center(
              child: Text("Loading data..."),
            );
          } else if (dataProvider.data!.isEmpty) {
            return const Center(
              child: Text("Dataset is empty."),
            );
          }
          return ListView.builder(
            itemCount: dataProvider.data!.length,
            itemBuilder: (context, index) {
              return HistoryListTile(data: dataProvider.data![index]);
            },
          );
        },
      ),
    );
  }
}

class HistoryListTile extends StatelessWidget {
  final List<dynamic> data;

  const HistoryListTile({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final dataFields = data.map((e) {
      return Expanded(
        child: Text(e.toString()),
      );
    }).toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: const Color.fromRGBO(217, 250, 237, 1),
      child: IntrinsicHeight(
        child: Row(children: [
          ...dataFields,
          const VerticalDivider(
            width: 3,
            thickness: 1,
            indent: 1,
            endIndent: 1,
            color: Colors.grey,
          ),
          SizedBox(
            width: 120,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.delete_forever),
            ),
          )
        ]),
      ),
    );
  }
}
