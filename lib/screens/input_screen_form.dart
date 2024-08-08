import 'dart:async';

import 'package:data_collector_app/dialogs.dart';
import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';

class InputScreenForm extends StatefulWidget {
  final Map dataset;
  const InputScreenForm({super.key, required this.dataset});

  @override
  State<InputScreenForm> createState() => _InputScreenFormState();
}

class _InputScreenFormState extends State<InputScreenForm> {
  final TextEditingController _controller = TextEditingController();

  List<(DateTime, num)> _data = [];
  bool _disableAdd = true;

  @override
  void initState() {
    super.initState();
    _loadNumbers();
  }

  Future<void> _loadNumbers() async {
    final data = await loadDataCsv();
    setState(() {
      _data = data;
    });
  }

  Future<void> _addSample(String sample, DateTime timestamp) async {
    final number = num.tryParse(sample);
    if (number != null) {
      setState(() {
        _data.add((timestamp, number));
        _controller.clear();
        _disableAdd = true;
      });
      await saveDataCsv(_data);
      print("saved sample at $timestamp");
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
        body: Column(
          children: [
            Container(
              width: 500,
              margin: const EdgeInsets.all(20),
              color: const Color.fromRGBO(240, 200, 255, 1.0),
              child: Column(
                children: [
                  InputForm(
                    dataset: widget.dataset,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: _disableAdd
                              ? null
                              : () {
                                  _addSample(_controller.text, DateTime.now());
                                },
                          label: const Text("Add"),
                          icon: const Icon(Icons.add),
                        ),
                        TextButton.icon(
                          onPressed: _disableAdd
                              ? null
                              : () async {
                                  if (_controller.text.isNotEmpty) {
                                    var timestamp = await showDateTimePicker(
                                        context: context);
                                    if (timestamp != null) {
                                      await _addSample(
                                          _controller.text, timestamp);
                                    }
                                  }
                                },
                          label: const Text("add at time"),
                          icon: const Icon(Icons.calendar_month),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Text("<history list>"),
          ],
        ));
  }
}

class InputForm extends StatefulWidget {
  final Map dataset;
  const InputForm({super.key, required this.dataset});

  @override
  State<InputForm> createState() => _InputFormState();
}

class _InputFormState extends State<InputForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Map schema = widget.dataset["schema"];

    List<Widget> formFields = [
      for (var k in schema.keys)
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: k,
              border: const OutlineInputBorder(),
            ),
          ),
        )
    ];

    return Form(
      key: _formKey,
      child: Column(
        children: formFields,
      ),
    );
  }
}

class InputFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InputFormAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text("Data Input (form)"));
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
