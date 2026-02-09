import 'package:data_app2/util/enums.dart';
import 'package:data_app2/widgets/generic_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final options = ["abra", "cadabra", "zim", "salabim"];
  testWidgets("description", (tester) async {
    // track selected values?
    final selections = <String>[];
    // setup
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenericAutocomplete<String>(
            options: options,
            onSelected: (v) {
              selections.add(v);
            },
            nameOf: (v) => v.toUpperCase(),
            searchMode: TextSearchMode.starts,
            initialValue: "zim",
          ),
        ),
      ),
    );

    expect(find.text("ZIM"), findsOneWidget);
  });
}
