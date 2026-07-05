import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/screens/blob_field_create_screen.dart';
import 'package:data_app2/view_models/blob_schema_edit_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/material.dart';

class BlobSchemaEditScreen extends StatefulWidget {
  final BlobSchemaRec? existing;
  final DBService db;
  const BlobSchemaEditScreen(this.db, this.existing, {super.key});

  @override
  State<BlobSchemaEditScreen> createState() => _BlobSchemaEditScreenState();
}

class _BlobSchemaEditScreenState extends State<BlobSchemaEditScreen> {
  late final BlobSchemaEditVm _vm;
  // text editing for inputs
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _vm = BlobSchemaEditVm(widget.existing, "TODO")..load();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
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
        final fields = _vm.fieldList;
        return EditScaffoldForVm(
          title: _vm.draft.name.isEmpty ? 'New Schema' : _vm.draft.name,
          vm: _vm,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("valid: ${_vm.isValid}, dirty: ${_vm.isDirty}"),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: _vm.setName,
              ),
              const SizedBox(height: 24),
              Text('Fields', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (fields.isEmpty)
                const Text('No fields', style: TextStyle(color: Colors.grey))
              else
                // not a Sliver context so ListView must be shrinkwrapped
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fields.length,
                  itemBuilder: (context, i) {
                    final MapEntry(key: name, value: spec) = fields[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _vm.removeField(name),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text("Add field")),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlobFieldCreateScreen(
                            existingFieldNames: _vm.draft.fields.keys.toSet(),
                            enumGroups:[ ], // TODO
                            onAdd: _vm.addField,
                          ),
                        ),
                      );
                    },
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
