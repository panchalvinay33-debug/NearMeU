import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/screens/nickname_screen.dart';

void main() {
  testWidgets('combined onboarding requires all fields before continuing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NicknameScreen(uid: 'u1', email: 'a@test.com')));
    expect(find.text('Build your NearMeU profile'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Continue'));
    expect(button.onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nickname'), 'Alex');
    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '25');
    await tester.tap(find.text('Male'));
    await tester.tap(find.text('Women'));
    await tester.pump();

    final enabled = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Continue'));
    expect(enabled.onPressed, isNotNull);
  });
}
