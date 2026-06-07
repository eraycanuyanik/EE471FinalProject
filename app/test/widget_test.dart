import 'package:flutter_test/flutter_test.dart';

import 'package:erisim/main.dart';

void main() {
  testWidgets('Ana menü üç modülü gösterir', (WidgetTester tester) async {
    await tester.pumpWidget(const ErisimApp());

    expect(find.text('SesVer'), findsOneWidget);
    expect(find.text('Duyar'), findsOneWidget);
    expect(find.text('Yanındayım'), findsOneWidget);
  });
}
