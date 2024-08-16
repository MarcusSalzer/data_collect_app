import 'package:data_collector_app/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputScreenForm extends StatefulWidget {
  final Map<String, dynamic> dataset;
  const InputScreenForm({super.key, required this.dataset});

  @override
  State<InputScreenForm> createState() => _InputScreenFormState();
}

class _InputScreenFormState extends State<InputScreenForm> {
  late final DataProvider _dataProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
  }

  void _save() async {
    await _dataProvider.saveDataCsv();
  }

  Future<void> _onExit() async {
    if (_dataProvider.unsavedChanges) {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _onExit();
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text(widget.dataset["name"]),
            // actions: [
            //   ElevatedButton.icon(
            //       onPressed: () {
            //         Navigator.pop(context);
            //       },
            //       icon: const Icon(Icons.save),
            //       label: const Text("Save")),
            // ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                InputForm(
                  dataset: widget.dataset,
                ),
                const HistoryList(),
              ],
            ),
          )),
    );
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
  // bool _disableAdd = true;
  // bool _isDataLoaded = false;

  // TODO MAKE sure to disable add if data not loaded yet

  // Handle input timestamps
  DateTime? _addDate;
  TimeOfDay? _addTime;

  late final List<String> _fieldNames;
  late final List<String> _dtypes;
  late final int _nFields;
  late final List<TextEditingController> _controllers;

  late final DataProvider _dataProvider;

  final FocusNode _firstFieldFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _fieldNames = List<String>.from(widget.dataset["schema"].keys);
    _dtypes = List<String>.from(widget.dataset["schema"].values);
    _nFields = _fieldNames.length;
    _controllers = List.generate(_nFields, (_) => TextEditingController());

    _dataProvider = Provider.of<DataProvider>(context, listen: false);
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    _firstFieldFocus.dispose();
    super.dispose();
  }

  // void _onDataLoaded() {
  //   if (!mounted) {
  //     return;
  //   }
  //   setState(() {
  //     // _isDataLoaded = true;
  //     _disableAdd = false;
  //   });
  // }

  /// Validate an input field based on its [dtype].
  String? _validateField(String text, String dtype, {bool allowEmpty = true}) {
    text = text.trim();
    if (text.isEmpty) {
      if (allowEmpty) {
        return null;
      } else {
        return "Please enter a value";
      }
    } else if (text.contains(",")) {
      return "Value cannot contain ',' (CSV separator)";
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

    // TODO: bug: 00:00
    var timestamp = (_addDate ?? DateTime.now())
        .copyWith(hour: _addTime?.hour, minute: _addTime?.minute);

    _dataProvider.addSample(timestamp, texts);

    // clear form
    for (var c in _controllers) {
      c.clear();
    }

    // focus first field
    _firstFieldFocus.requestFocus();

    // clear add-timestamps
    setState(() {
      _addDate = null;
      _addTime = null;
    });
  }

  void _pickDate() async {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select a date"),
                  SizedBox.square(
                    dimension: 400,
                    child: CalendarDatePicker(
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1970),
                      lastDate: DateTime(2200),
                      onDateChanged: (date) {
                        setState(() {
                          _addDate = date;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  // void _pickDateOld() async {
  //   var date = await showDatePicker(
  //     context: context,
  //     firstDate: DateTime(0),
  //     lastDate: DateTime(3000),
  //   );
  //   setState(() {
  //     _addDate = date;
  //   });
  // }

  String _dateString() {
    if (_addDate == null) {
      return "Today";
    }
    var d = _addDate!;
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  void _pickTime() async {
    var time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    setState(() {
      _addTime = time;
    });
  }

  String _timeString() {
    if (_addTime == null) {
      return "Now";
    }
    var t = _addTime!;
    return "${t.hour}:${t.minute}";
  }

  @override
  Widget build(BuildContext context) {
    // _disableAdd = _dataProvider.data != null;

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
              onFieldSubmitted: (value) {
                print("enter");
                _addSample();
              },
              focusNode: i == 0 ? _firstFieldFocus : null, // only for first
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
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _pickDate();
                    },
                    label: Text(_dateString()),
                    icon: const Icon(Icons.calendar_month),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _pickTime();
                    },
                    label: Text(_timeString()),
                    icon: const Icon(Icons.timelapse),
                  ),
                ],
              ),
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
                onPressed: () {
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
      child: Consumer<DataProvider>(
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
              return HistoryListTile(dataSamp: dataProvider.data![index]);
            },
          );
        },
      ),
    );
  }
}

class HistoryListTile extends StatelessWidget {
  final DataSample dataSamp;

  const HistoryListTile({super.key, required this.dataSamp});

  final VerticalDivider divider = const VerticalDivider(
    width: 3,
    thickness: 1,
    indent: 1,
    endIndent: 1,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    final dataFields = dataSamp.data.map((e) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SelectionArea(child: Text(e.toString())),
        ),
      );
    }).toList();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: IntrinsicHeight(
        child: Row(children: [
          SizedBox(
            width: 200,
            child: SelectionArea(
                child: Text(dataSamp.timestamp.toString().split(".")[0])),
          ),
          divider,
          ...dataFields,
          divider,
          SizedBox(
            width: 120,
            child: IconButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false)
                    .removeSample(dataSamp);
              },
              icon: const Icon(Icons.delete_forever),
            ),
          )
        ]),
      ),
    );
  }
}
