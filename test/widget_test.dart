import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/app.dart';

void main() {
  testWidgets('Pomodoro UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the Pomodoro title is present.
    expect(find.text('Pomodoro'), findsOneWidget);

    // Verify that the start button is present.
    expect(find.text('START'), findsOneWidget);
  });
}
