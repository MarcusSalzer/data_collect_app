import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/create_tabular_screen.dart';
import 'package:data_app2/user_tabular.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabularScreen extends StatelessWidget {
  const TabularScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return ChangeNotifierProvider<TabularModel>(
      // make model, and start async init
      create: (context) => TabularModel(appState.db)..init(),
      child: Consumer<TabularModel>(
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
                            return UserTableListTile(tables[index]);
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
  final TabularProcessor table;

  const UserTableListTile(this.table, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.table_bar),
      title: Text(table.name),
    );
  }
}
