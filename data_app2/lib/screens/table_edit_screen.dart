import 'package:data_app2/fmt.dart';
import 'package:data_app2/screens/table_record_edit_screen.dart';
import 'package:data_app2/user_tabular.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableEditScreen extends StatelessWidget {
  final TableProcessor table;
  late final Future<void> _initF;

  TableEditScreen(this.table, {super.key}) {
    // start loading data
    _initF = table.init();
  }
  @override
  Widget build(BuildContext context) {
    // for deleting table
    final tModel = Provider.of<TableManager>(context, listen: false);
    return FutureBuilder(
        future: _initF,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: Text("Loading records..."));
          }
          if (snap.hasError) {
            return Center(child: Text("Error loading records"));
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(table.name),
              actions: [
                MenuAnchor(
                  builder: (context, controller, child) => IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: Icon(Icons.more_vert),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ConfirmDialog(
                            title: "Clear all records?",
                            action: table.truncate,
                          ),
                        );
                      },
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                      ),
                      child: Text("Clear table"),
                    ),
                    MenuItemButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ConfirmDialog(
                            title: "Permanently delete table?",
                            action: () async {
                              await tModel.deleteTable(table);
                              if (context.mounted) {
                                // leave edit page
                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      },
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                      ),
                      child: Text("Delete table"),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: TableRecordsList(table),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TableRecordEditScreen(table),
                        ),
                      );
                    },
                    child: Text("New"),
                  ),
                )
              ],
            ),
          );
        });
  }
}

class TableRecordsList extends StatelessWidget {
  final TableProcessor table;

  const TableRecordsList(
    this.table, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: table,
      child: Consumer<TableProcessor>(
        builder: (context, value, child) {
          final data = value.data;
          if (data.isEmpty) {
            return Center(child: Text("No records"));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) =>
                TableRecordListTile(rec: data[index], table: table),
          );
        },
      ),
    );
  }
}

class TableRecordListTile extends StatelessWidget {
  const TableRecordListTile({
    super.key,
    required this.rec,
    required this.table,
  });

  final TableProcessor table;
  final TableRecord rec;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(dtFreqFmt(rec.timestamp, table.freq)),
      title: Text(rec.data.values.join(", ")),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableRecordEditScreen(
              table,
              record: rec,
            ),
          ),
        );
      },
    );
  }
}
