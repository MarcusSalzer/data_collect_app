import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/widgets/schema_display_card.dart';
import 'package:flutter/material.dart';

class SchemaInfoScreen extends StatelessWidget {
  const SchemaInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Known Schemas")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: CsvSchemasConst.byImportRole.entries.map((e) => SchemaDisplayCard(e.key.name, e.value)).toList(),
          ),
        ),
      ),
    );
  }
}
