import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/view_models/user_enum_edit_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';

class UserEnumEditScreen extends StatefulWidget {
  final UserEnumRec? existing;
  final DBService db;
  const UserEnumEditScreen(this.db, this.existing, {super.key});

  @override
  State<UserEnumEditScreen> createState() => _UserEnumEditScreenState();
}

class _UserEnumEditScreenState extends State<UserEnumEditScreen> {
  late final UserEnumEditVm _vm;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _newValueCtrl;

  @override
  void initState() {
    super.initState();
    _vm = UserEnumEditVm(widget.existing, widget.db);
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _newValueCtrl = TextEditingController();
    if (widget.existing != null) {
      _vm.load();
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _newValueCtrl.dispose();
    super.dispose();
  }

  void _submitNewValue() {
    final name = _newValueCtrl.text.trim();
    if (name.isEmpty) return;
    _vm.addValue(name);
    _newValueCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return EditScaffoldForVm(
          title: _vm.draft.name.isEmpty ? 'New Enum' : _vm.draft.name,
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
              Text('Values', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_vm.valueDrafts.isEmpty)
                const Text('No values yet', style: TextStyle(color: Colors.grey))
              else
                // not a Sliver context so ListView must be shrinkwrapped
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vm.valueDrafts.length,
                  itemBuilder: (context, i) {
                    final value = _vm.valueDrafts[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(value.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _vm.removeValue(i),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newValueCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Add value',
                        hintText: 'e.g. pizza',
                      ),
                      onSubmitted: (_) => _submitNewValue(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _submitNewValue,
                  ),
                ],
              ),
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
