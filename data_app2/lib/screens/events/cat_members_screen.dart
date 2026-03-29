import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/view_models/cat_members_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _CatMemberslist extends StatelessWidget {
  final UnmodifiableListView<EvtTypeRec> types;
  final Color Function(EvtTypeRec) colorFor;
  const _CatMemberslist(this.types, this.colorFor);
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: types.length,
      itemBuilder: (context, idx) {
        final t = types[idx];
        return ListTile(
          leading: CircleAvatar(radius: 5, backgroundColor: colorFor(t)),
          title: Text(t.name),
          trailing: IconButton(
            onPressed: () {
              context.read<EvtCatMembersVm>().unlink(t);
            },
            icon: Icon(Icons.close),
          ),
        );
      },
    );
  }
}

class CatMembersScreen extends StatelessWidget {
  final EvtCatRec cat;
  const CatMembersScreen(this.cat, {super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);
    return ChangeNotifierProvider(
      create: (context) {
        final app = context.read<AppState>();
        return EvtCatMembersVm(cat, app.db, app.evtTypeManager)..load();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(cat.name),
        ),
        body: Builder(
          builder: (context) {
            final vm = context.watch<EvtCatMembersVm>();

            final types = vm.types;

            if (types == null) {
              return Center(child: Text("Loading..."));
            }
            if (types.isEmpty) {
              return Center(child: Text("No members"));
            }
            return _CatMemberslist(
              types,
              (t) => context.read<AppState>().evtTypeManager.colorFor(t, prefs.colorSpread),
            );
          },
        ),
      ),
    );
  }
}
