import 'package:data_app2/csv/csv_schema.dart';
import 'package:flutter/material.dart';

class SchemaDisplayCard extends StatelessWidget {
  const SchemaDisplayCard(this.name, this.schema, {super.key});
  final String name;
  final CsvSchema schema;

  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);
    return Container(
      color: thm.colorScheme.primaryContainer,
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(name, style: TextStyle(fontSize: 20)),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: schema.writeCols.map((c) {
              final isReq = schema.requiredCols.contains(c);
              return Chip(
                label: Text(isReq ? c : "($c)", style: TextStyle(fontWeight: isReq ? FontWeight.bold : null)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.all(Radius.circular(6))),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
