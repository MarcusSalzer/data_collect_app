import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/view_models/evt_cat_detail_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EvtCatDetailScreen extends StatelessWidget {
  const EvtCatDetailScreen(this.stored, {super.key});

  final EvtCatRec? stored;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EvtCatDetailVm(stored, context.read<AppState>()),
      child: Consumer<EvtCatDetailVm>(
        builder: (context, vm, _) => EditScaffold<EvtCatRec>(
          title: stored == null ? "New Category" : "Edit Category",
          vm: vm,
          body: _EditForm(vm),
        ),
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  final EvtCatDetailVm vm;

  const _EditForm(this.vm);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(labelText: "Name"),
      onChanged: vm.updateName,
      initialValue: vm.draft.name,
    );
  }
}
