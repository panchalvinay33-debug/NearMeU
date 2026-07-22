import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/models/app_user.dart';
import 'package:nearmeu/widgets/user_info.dart';

void main() {
  testWidgets(
    'nearby user info shows distance and state without city or pinpoint data',
    (tester) async {
      final user = AppUser(
        uid: 'nearby-user',
        email: 'nearby@example.com',
        nickname: 'Nearby',
        gender: 'Woman',
        lookingFor: 'Men',
        createdAt: DateTime(2026, 1, 1),
        age: 23,
        city: 'Private City',
        state: 'CA',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                UserInfo(user: user, distanceText: '1 km'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1 km • CA'), findsOneWidget);
      expect(find.textContaining('Private City'), findsNothing);
      expect(find.textContaining('37.7749'), findsNothing);
      expect(find.textContaining('-122.4194'), findsNothing);
    },
  );
}
