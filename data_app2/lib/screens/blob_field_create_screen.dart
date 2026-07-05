import 'package:data_app2/data/user_schema.dart';
import 'package:flutter/material.dart';

class BlobFieldCreateScreen extends StatefulWidget {
  const BlobFieldCreateScreen({
    super.key,
    required this.existingFieldNames,
    required this.enumGroups,
    required this.onAdd,
  });

  /// Used to reject duplicate names.
  final Set<String> existingFieldNames;

  /// Names of user-defined enum groups available to pick from.
  final List<String> enumGroups;
  final void Function(String name, BlobFieldSpec spec) onAdd;

  @override
  State<BlobFieldCreateScreen> createState() => _BlobFieldCreateScreenState();
}

class _BlobFieldCreateScreenState extends State<BlobFieldCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  BlobFieldType? _type;
  bool _nullable = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _type != null && _nameController.text.trim().isNotEmpty;

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name required';
    if (widget.existingFieldNames.contains(name)) return 'Field "$name" already exists';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false) || _type == null) return;
    widget.onAdd(_nameController.text.trim(), BlobFieldSpec(_type!, nullable: _nullable));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New field')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Field name'),
              validator: _validateName,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text('Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FieldTypeSelector(
              enumGroups: widget.enumGroups,
              onChanged: (type) => setState(() => _type = type),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Optional'),
              subtitle: const Text('Field may be left empty'),
              value: _nullable,
              onChanged: (v) => setState(() => _nullable = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: const Text('Add field'),
          ),
        ),
      ),
    );
  }
}

enum _TypeKind { int, decimal, bool, timestamp, enumType }

class FieldTypeSelector extends StatefulWidget {
  const FieldTypeSelector({
    super.key,
    required this.enumGroups,
    required this.onChanged,
  });

  final List<String> enumGroups;
  final ValueChanged<BlobFieldType?> onChanged;

  @override
  State<FieldTypeSelector> createState() => _FieldTypeSelectorState();
}

class _FieldTypeSelectorState extends State<FieldTypeSelector> {
  _TypeKind? _kind;
  String? _enumGroup;

  void _emit() {
    final type = switch (_kind) {
      _TypeKind.int => const DInt(),
      _TypeKind.decimal => const DDecimal(),
      _TypeKind.bool => const DBool(),
      _TypeKind.timestamp => const DTimestamp(),
      _TypeKind.enumType => _enumGroup == null ? null : DEnum(_enumGroup!),
      null => null,
    };
    widget.onChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<_TypeKind>(
          initialValue: _kind,
          decoration: const InputDecoration(labelText: 'Data type'),
          items: const [
            DropdownMenuItem(value: _TypeKind.int, child: Text('Integer')),
            DropdownMenuItem(value: _TypeKind.decimal, child: Text('Decimal')),
            DropdownMenuItem(value: _TypeKind.bool, child: Text('Yes / No')),
            DropdownMenuItem(value: _TypeKind.timestamp, child: Text('Timestamp')),
            DropdownMenuItem(value: _TypeKind.enumType, child: Text('Choice (enum)')),
            // Future: List(...), Tuple(...) — each pushes a nested
            // FieldTypeSelector for the element/sub-field type(s).
          ],
          onChanged: (kind) {
            setState(() {
              _kind = kind;
              _enumGroup = null;
            });
            _emit();
          },
        ),
        if (_kind == _TypeKind.enumType) ...[
          const SizedBox(height: 12),
          if (widget.enumGroups.isEmpty)
            const Text('No enum groups yet — create one first.')
          else
            DropdownButtonFormField<String>(
              initialValue: _enumGroup,
              decoration: const InputDecoration(labelText: 'Enum group'),
              items: [
                for (final g in widget.enumGroups) DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (g) {
                setState(() => _enumGroup = g);
                _emit();
              },
            ),
        ],
      ],
    );
  }
}
