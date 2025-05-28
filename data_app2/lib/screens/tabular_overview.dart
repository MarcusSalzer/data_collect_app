import 'package:data_app2/app_state.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/screens/create_tabular_screen.dart';
import 'package:data_app2/screens/table_edit_screen.dart';
import 'package:data_app2/user_tabular.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabularScreen extends StatelessWidget {
  const TabularScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return ChangeNotifierProvider<TableManager>(
      // make model, and start async init
      create: (context) => TableManager(appState.db)..init(),
      child: Consumer<TableManager>(
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Datasets"),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateTabularScreen(model),
                        ));
                  },
                  label: Text("add"),
                  icon: Icon(Icons.add),
                ),
              ],
            ),
            // await model init
            body: FutureBuilder(
              future: model.initFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: Text("Loading tables..."));
                }
                if (snap.hasError) {
                  return Center(child: Text("Error loading tables"));
                }
                final tables = model.tableProcessors;
                if (tables.isEmpty) {
                  return Center(child: Text("No tables"));
                }
                return Center(
                  child: Column(
                    children: [
                      Text("Have ${tables.length} tables"),
                      Expanded(
                        child: ListView.builder(
                          itemCount: tables.length,
                          itemBuilder: (context, index) {
                            return UserTableListTile(tables[index], model);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class UserTableListTile extends StatelessWidget {
  final TableProcessor table;
  final TableManager tModel;

  const UserTableListTile(this.table, this.tModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.table_bar),
      title: Text(table.name),
      subtitle: Text(
        table.dtypes.map((t) => t.name).join(", "),
        style: TextStyle(fontFamily: "monospace"),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(table.freq.name.capitalized),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: tModel,
              child: TableEditScreen(table),
            ),
          ),
        );
      },
    );
  }
}
