import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_app/main.dart'; // ← make sure this matches your app name

void main() {
  testWidgets('App launches and displays login button', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const SportsApp());

    // Verify login button is found
    expect(find.text('Login'), findsOneWidget);

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // After login, main navigation should appear
    expect(find.byIcon(Icons.announcement), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}