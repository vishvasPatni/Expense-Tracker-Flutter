import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/app.dart';

void main() {
  testWidgets('App shows config hint without dart-define', (tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pump();
    expect(find.textContaining('app.env'), findsOneWidget);
  });
}
