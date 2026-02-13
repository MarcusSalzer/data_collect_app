import 'package:data_app2/screens/color_spread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

IconButton _findSaveBtn(WidgetTester tester) {
  return tester.widget<IconButton>(
    find.byWidgetPredicate((w) => w is IconButton && (w.icon as Icon).icon == Icons.save),
  );
}

const initVal = 0.4;
void main() {
  final initPercent = NumberFormat.decimalPercentPattern(decimalDigits: 0).format(initVal);
  testWidgets("init OK", (tester) async {
    double value = initVal;
    // setup
    await tester.pumpWidget(
      MaterialApp(
        home: ColorSpreadScreen(
          initVal: value,
          saveAction: (v) async {
            value = v;
            return true;
          },
        ),
      ),
    );

    expect(find.text(initPercent), findsOneWidget, reason: "show initial %");
    expect(find.text("Color spread"), findsOneWidget, reason: "shows title");
    expect(find.byType(Slider), findsOneWidget);

    expect(_findSaveBtn(tester).onPressed, isNull, reason: "save disabled initially");
  });

  testWidgets("slider works", (tester) async {
    double value = initVal;
    // setup
    await tester.pumpWidget(
      MaterialApp(
        home: ColorSpreadScreen(
          initVal: value,
          saveAction: (v) async {
            value = v;
            return true;
          },
        ),
      ),
    );

    // NOTE: pixel coordinates
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text("Color spread *"), findsOneWidget, reason: "shows title dirty");
    expect(_findSaveBtn(tester).onPressed, isNotNull, reason: "save button enabled");
    // Percent should no longer be 40%
    expect(find.text(initPercent), findsNothing);
  });
  testWidgets("save button works", (tester) async {
    double value = initVal;
    // setup
    await tester.pumpWidget(
      MaterialApp(
        home: ColorSpreadScreen(
          initVal: value,
          saveAction: (v) async {
            value = v;
            return true;
          },
        ),
      ),
    );

    // NOTE: pixel coordinates
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(value, isNot(initVal));
    expect(find.textContaining("*"), findsNothing, reason: "not dirty after save");
  });
}
