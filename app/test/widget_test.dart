import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:human_contact/app.dart';

void main() {
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HumanContactApp(),
      ),
    );

    // Verify the welcome screen loads
    expect(find.text('The place to meet\nreal humans.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
