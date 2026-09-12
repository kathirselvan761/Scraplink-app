import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ScrapLink Collector App splash smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScrapLinkCollectorApp());
    expect(find.text('ScrapLink'), findsOneWidget);
    expect(find.text('COLLECTOR COMPANION'), findsOneWidget);
    // Allow splash timer to finish
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });
}

