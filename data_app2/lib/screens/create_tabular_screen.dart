import 'package:data_app2/db_service.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/user_tabular.dart';
import 'package:flutter/material.dart';

class CreateTabularScreen extends StatelessWidget {
  final TableManager model;
  const CreateTabularScreen(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create dataset"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: CreateTabularForm(model),
      ),
    );
  }
}

class CreateTabularForm extends StatefulWidget {
  final TableManager model;

  const CreateTabularForm(this.model, {super.key});

  @override
  State<CreateTabularForm> createState() => _CreateTabularFormState();
}

class _CreateTabularFormState extends State<CreateTabularForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameTec = TextEditingController();
  final _fieldTecList = <TextEditingController>[];
  final _candidateNames = <String>[];
  TableFreq _chosenFreq = TableFreq.free;
  @override
  Widget build(BuildContext context) {
    final fieldElements = _fieldTecList.indexed.map(
      (e) {
        final idx = e.$1;
        final tec = e.$2;
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                  decoration: InputDecoration(hintText: "field"),
                  controller: tec,
                  validator: (value) {
                    final v = value?.trim();
                    if (v == null || v.isEmpty) {
                      return 'Please enter a field name';
                    } else {
                      if (_candidateNames.contains(v)) {
                        return "Please provide a unique name";
                      }
                    }
                    _candidateNames.add(v);
                    return null;
                  }),
            ),
            IconButton(
                onPressed: () {
                  removeField(idx);
                },
                icon: Icon(Icons.playlist_remove))
          ],
        );
      },
    ).toList();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(hintText: "Name"),
            controller: _nameTec,
            validator: (value) {
              final v = value?.trim();
              if (v == null || v.isEmpty) {
                return 'Please enter a dataset name';
              } else {
                var currentNames = widget.model.tableNames;
                if (currentNames.contains(v)) {
                  return "Already exists";
                }
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Text(
                "Fields",
                style: TextStyle(fontSize: 20),
              ),
              Column(
                children: fieldElements,
              ),
              TextButton(onPressed: addField, child: Text("add field")),
            ],
          ),
          // frequency picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: TableFreq.values
                .map(
                  (tf) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Radio<TableFreq>(
                          value: tf,
                          groupValue: _chosenFreq,
                          onChanged: updateFreq,
                        ),
                        Text(tf.name.capitalized),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 20),
          if (_fieldTecList.isNotEmpty)
            TextButton(onPressed: save, child: Text("Save")),
        ],
      ),
    );
  }

  void updateFreq(TableFreq? value) {
    setState(() {
      _chosenFreq = value ?? _chosenFreq;
    });
  }

  /// Add a field to the form
  void addField() {
    setState(() {
      final tec = TextEditingController();
      _fieldTecList.add(tec);
    });
  }

  /// Remove a field from the form
  void removeField(int idx) {
    setState(() {
      final tec = _fieldTecList.removeAt(idx);
      tec.dispose();
    });
  }

  /// Save form input as a new tabular dataset
  void save() {
    // validate form
    _candidateNames.clear();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tableName = _nameTec.text;
    final colNames = _fieldTecList.map((t) => t.text).toList();
    widget.model.newTable(tableName, colNames, _chosenFreq);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameTec.dispose();
    super.dispose();
  }
}
