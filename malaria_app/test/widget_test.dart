import 'package:flutter_test/flutter_test.dart';

import 'package:malaria_app/main.dart';

void main() {
  testWidgets('shows malaria detection home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MalariaApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Malaria Detection'), findsOneWidget);
    expect(find.text('Capture Image'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('View Result History'), findsOneWidget);
    expect(find.text('About App'), findsOneWidget);
  });
}
