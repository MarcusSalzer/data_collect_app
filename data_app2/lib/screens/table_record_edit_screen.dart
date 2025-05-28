import 'package:data_app2/db_service.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/user_tabular.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';

class TableRecordEditScreen extends StatefulWidget {
  final TableProcessor table;

  // optionally keep editing a record
  final TableRecord? record;

  const TableRecordEditScreen(this.table, {super.key, this.record});

  @override
  State<TableRecordEditScreen> createState() => _TableRecordEditScreenState();
}

class _TableRecordEditScreenState extends State<TableRecordEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final tecs = <String, TextEditingController>{};

  // Make non-final to allow changing?
  late final TableRecord record;
  bool isNew = false;

  _TableRecordEditScreenState() {
    // make new record now if missing
  }

  // Find take widget record, or make a new if missing
  @override
  void initState() {
    final wRec = widget.record;
    if (wRec != null) {
      record = wRec;
    } else {
      isNew = true;
      record = TableRecord(null, widget.table.now());
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;

    // Make all fields
    final fieldInputs = table.columns.map((c) {
      tecs[c.name] =
          TextEditingController(text: record.data[c.name]?.toString());

      return Row(
        children: [
          Expanded(
            child: Text(c.name),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              decoration: InputDecoration(hintText: c.dtype.name),
              controller: tecs[c.name],
              validator: (value) {
                try {
                  c.parse(value);
                } catch (e) {
                  return "parse error";
                }
                return null;
              },
            ),
          ),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () {
          save();
        }),
        title: Text("${isNew ? "New" : "Record"} in '${widget.table.name}'"),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: "delete",
                    action: () async {
                      final didDelete = await table.delete(record);
                      if (context.mounted) {
                        if (didDelete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("deleted $record"),
                            ),
                          );
                        }
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
              icon: Icon(Icons.delete_forever))
        ],
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TableRecTimestampDisplay(
                  freq: table.freq,
                  rec: record,
                ),
                Divider(),
                Column(
                  children: fieldInputs,
                ),
              ],
            ),
          ),
          if (!isNew) Text("id: ${record.id}")
        ],
      ),
    );
  }

  Future<void> save() async {
    final state = _formKey.currentState;
    if (state == null) return;

    if (state.validate()) {
      final data = <String, dynamic>{};
      for (var col in widget.table.columns) {
        data[col.name] = col.parse(tecs[col.name]?.text);
      }

      record.data = data;
      widget.table.save(record);
      // then leave page
      Navigator.maybePop(context);
    }
  }

  @override
  void dispose() {
    for (var t in tecs.values) {
      t.dispose();
    }
    super.dispose();
  }
}

class TableRecTimestampDisplay extends StatelessWidget {
  final TableFreq freq;
  final TableRecord rec;

  const TableRecTimestampDisplay(
      {super.key, required this.freq, required this.rec});
  @override
  Widget build(BuildContext context) {
    final txt = dtFreqFmt(rec.timestamp, freq);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(txt),
    );
  }
}
