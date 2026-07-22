import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/app_user.dart';
import 'package:nearmeu/screens/user_profile_screen.dart';

void main() {
  testWidgets('premium user profile shows hero cards and no standalone block button', (tester) async {
    final user = AppUser(
      uid: 'u2',
      email: 'user@test.com',
      nickname: 'Mia',
      gender: 'Female',
      lookingFor: 'Men',
      createdAt: DateTime(2026),
      age: 28,
      city: 'Austin',
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    await tester.pumpWidget(MaterialApp(home: UserProfileScreen(user: user, loadBlockState: false)));
    expect(find.text('Mia, 28'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Looking For'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Chat Now'), findsOneWidget);
    expect(find.text('Block User'), findsNothing);
  });
}
