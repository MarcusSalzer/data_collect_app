import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/user_table_edit_screen.dart';
import 'package:data_app2/view_models/user_table_index_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    final indexVm = context.watch<UserTableIndexVm>();

    final items = indexVm.items;
    if (items == null) {
      return Center(child: Text("Loading..."));
    }
    if (items.isEmpty) {
      return Center(child: Text("No datasets"));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final rec = items[i];
        return ListTile(
          title: Text(rec.name),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => UserTableEditScreen(context.read<AppState>().db, rec),
                  ),
                )
                .then((_) {
                  if (context.mounted) {
                    // Reload data after possible edits
                    context.read<UserTableIndexVm>().load();
                  }
                });
          },
        );
      },
    );
  }
}

class UsertableScreen extends StatelessWidget {
  const UsertableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctxCreate) {
            final app = ctxCreate.read<AppState>();
            return UserTableIndexVm(app.db.userTables)..load();
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final count = context.watch<UserTableIndexVm>().items?.length;
              return Text("Datasets ($count)");
            },
          ),
        ),
        body: _Body(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => UserTableEditScreen(context.read<AppState>().db, null),
                  ),
                )
                .then((_) {
                  if (context.mounted) {
                    // Reload data after possible edits
                    context.read<UserTableIndexVm>().load();
                  }
                });
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
