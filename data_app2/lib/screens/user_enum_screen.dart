import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/user_enum_edit_screen.dart';
import 'package:data_app2/view_models/user_enum_index_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    final indexVm = context.watch<UserEnumIndexVm>();

    final items = indexVm.items;
    if (items == null) {
      return Center(child: Text("Loading..."));
    }
    if (items.isEmpty) {
      return Center(child: Text("No enums"));
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
                    builder: (_) => UserEnumEditScreen(context.read<AppState>().db, rec),
                  ),
                )
                .then((_) {
                  if (context.mounted) {
                    // Reload data after possible edits
                    context.read<UserEnumIndexVm>().load();
                  }
                });
          },
        );
      },
    );
  }
}

class UserEnumScreen extends StatelessWidget {
  const UserEnumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctxCreate) {
            final app = ctxCreate.read<AppState>();
            return UserEnumIndexVm(app.db.userEnums)..load();
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final count = context.watch<UserEnumIndexVm>().items?.length;
              return Text("Enums ($count)");
            },
          ),
        ),
        body: _Body(),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => UserEnumEditScreen(context.read<AppState>().db, null),
                      ),
                    )
                    .then((_) {
                      if (context.mounted) {
                        // Reload data after possible edits
                        context.read<UserEnumIndexVm>().load();
                      }
                    });
              },
              child: Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}
