import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clarivo/main.dart';

void main() {
  testWidgets('Clarivo homepage smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1800, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ClarivoApp());

    expect(find.text('Hello, Azra 👋'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Market Snapshot'), findsOneWidget);
  });
}
