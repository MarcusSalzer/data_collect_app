import 'dart:async';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
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

  Future<DateTime?> _showDateTimePicker({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    initialDate ??= DateTime.now();

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(-1000),
      lastDate: DateTime(10000),
    );

    if (date == null) return null;

    if (!context.mounted) return date;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    return selectedTime == null
        ? date
        : DateTime(
            date.year,
            date.month,
            date.day,
            selectedTime.hour,
            selectedTime.minute,
          );
  }

  String _formatDateTime(DateTime dt) {
    return dt.toString().split(".")[0];
  }

  @override
  Widget build(BuildContext context) {
    // TODO: need to reload series?
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 400,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Input (enter to add)',
                ),
                onSubmitted: (text) {
                  _addSample(text, DateTime.now());
                },
                onChanged: (text) {
                  setState(() {
                    _disableAdd = text.isEmpty;
                  });
                },
              ),
            ),

            // add button
            TextButton.icon(
              onPressed: _disableAdd
                  ? null
                  : () {
                      _addSample(_controller.text, DateTime.now());
                    },
              label: const Text("Add"),
              icon: const Icon(Icons.add),
            ),

            // custom time button
            TextButton.icon(
              onPressed: _disableAdd
                  ? null
                  : () async {
                      if (_controller.text.isNotEmpty) {
                        var timestamp =
                            await _showDateTimePicker(context: context);
                        if (timestamp != null) {
                          await _addSample(_controller.text, timestamp);
                        }
                      }
                    },
              label: const Text("add at time"),
              icon: const Icon(Icons.calendar_month),
            )
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _data.length,
            itemBuilder: (context, index) {
              return dataListTile(index);
            },
          ),
        ),
      ],
    );
  }

  ListTile dataListTile(int index) {
    return ListTile(
      title: Text(_data[index].$2.toString()),
      leading: Text(_formatDateTime(_data[index].$1)),
      trailing: SizedBox(
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                print("TODO: editing");
              },
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _data.removeAt(index);
                });
                saveDataCsv(_data);
                print("deleted sample $index"); // TODO: implement trash
              },
              icon: const Icon(Icons.delete_forever),
            ),
          ],
        ),
      ),
    );
  }
}

class SamplesList extends StatelessWidget {
  final List<(DateTime, int)> history;

  const SamplesList({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class InputAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InputAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text("Data Input"));
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(56);
}
