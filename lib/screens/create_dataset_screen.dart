import 'package:data_collector_app/constants.dart';
import 'package:data_collector_app/utility/data_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreateDatasetScreen extends StatelessWidget {
  const CreateDatasetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New dataset"),
      ),
      body: const Padding(
        padding: EdgeInsets.fromLTRB(100, 10, 100, 50),
        child: DatasetEditor(),
      ),
    );
  }
}

class DatasetEditor extends StatefulWidget {
  const DatasetEditor({
    super.key,
  });

  @override
  State<DatasetEditor> createState() => _DatasetEditorState();
}

class _DatasetEditorState extends State<DatasetEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<Map<String, dynamic>> _fields = [];

  // late FocusNode _focus;

  @override
  void initState() {
    super.initState();
  }

  void _removeField(int index) {
    setState(() {
      _fields[index]["fieldNameController"].dispose();
      _fields.removeAt(index);
    });
  }

  void _addField() {
    setState(() {
      _fields.add({
        "fieldNameController": TextEditingController(),
        'type': allowedDatatypes[0]
      });
    });
  }

  /// Validate input and save dataset to [DatasetIndexProvider] if valid.
  void _saveDataset() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate field names
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one field.")),
      );
      return;
    }
    final List fieldNames = _fields
        .map((field) => field["fieldNameController"].text.trim())
        .toList();
    if (Set.from(fieldNames).length < fieldNames.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please use unique field names.")),
      );
      return;
    }

    // Save dataset
    final datasetName = _nameController.text;
    var schema = <String, String>{
      // "timestamp": "datetime",
      for (var f in _fields) f["fieldNameController"].text.trim(): f["type"]
    };

    final newDataset = Dataset(datasetName, schema, 0);

    // Access the DatasetProvider and add the dataset

    Provider.of<DataModel>(context, listen: false).addDataset(newDataset);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Created new dataset: ${newDataset.name}")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Dataset Name'),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a dataset name';
              } else {
                var currentNames =
                    Provider.of<DataModel>(context, listen: false)
                        .datasets
                        .map((ds) => ds.name);
                if (currentNames.contains(value.trim())) {
                  return "Already exists";
                }
              }
              return null;
            },
            onFieldSubmitted: (text) {
              if (_fields.isEmpty) {
                _addField();
              }
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _fields[index]["fieldNameController"],
                          decoration:
                              const InputDecoration(labelText: 'Field Name'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Field name cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _fields[index]['type'],
                        items: allowedDatatypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _fields[index]['type'] = newValue!;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () => _removeField(index),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _addField,
            child: const Text('Add Field'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveDataset,
            child: const Text('Save Dataset'),
          ),
        ],
      ),
    );
  }

  /// Dispose of all TextEditingControllers.
  @override
  void dispose() {
    _nameController.dispose();
    for (var field in _fields) {
      field["fieldNameController"].dispose();
    }
    super.dispose();
  }
}
