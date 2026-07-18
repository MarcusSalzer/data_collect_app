import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/widgets/schema_display_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('evt schema can be displayed', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SchemaDisplayCard("ok", CsvSchemasConst.evtHuman))));

    // optional cols in parentheses
    for (var c in CsvSchemasConst.evtHuman.optionalCols) {
      expect(find.text("($c)"), findsOneWidget);
    }
    // required cols
    for (var c in CsvSchemasConst.evtHuman.requiredCols) {
      expect(find.text(c), findsOneWidget);
    }
  });
}
