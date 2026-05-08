import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/view_models/user_table_edit_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';

class UserTableEditScreen extends StatefulWidget {
  final UserTableRec? existing;
  final DBService db;
  const UserTableEditScreen(this.db, this.existing, {super.key});

  @override
  State<UserTableEditScreen> createState() => _UserTableEditScreenState();
}

class _UserTableEditScreenState extends State<UserTableEditScreen> {
  late final UserTableEditVm _vm;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _vm = UserTableEditVm(widget.existing, widget.db);
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    if (widget.existing != null) {
      _vm.load();
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return EditScaffoldForVm(
          title: _vm.draft.name.isEmpty ? 'New' : _vm.draft.name,
          vm: _vm,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: _vm.setName,
              ),
              const SizedBox(height: 24),
              Text('Fields', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              const SizedBox(height: 8),

              if (_vm.errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(_vm.errorMsg!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        );
      },
    );
  }
}
