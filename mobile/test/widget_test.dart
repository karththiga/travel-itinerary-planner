import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/app/travel_app.dart';

void main() {
  testWidgets('Signup and login lead to home and logout returns to login', (
    tester,
  ) async {
    var signedUp = false;
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/auth/signup':
          expect(jsonDecode(request.body), {
            'email': 'test@example.com',
            'password': 'a-long passphrase',
          });
          signedUp = true;
          return http.Response(
            jsonEncode({'token': 'token', 'expiresIn': 3600}),
            201,
          );
        case '/api/auth/login':
          return signedUp
              ? http.Response(
                  jsonEncode({'token': 'token', 'expiresIn': 3600}),
                  200,
                )
              : http.Response(
                  jsonEncode({'message': 'Invalid email or password.'}),
                  401,
                );
        case '/api/auth/logout':
          expect(request.headers['authorization'], 'Bearer token');
          return http.Response('', 204);
        case '/api/attractions':
          return http.Response('[]', 200);
        default:
          fail('Unexpected API request: ${request.url}');
      }
    });
    addTearDown(client.close);
    await tester.pumpWidget(TravelApp(client: client));

    Future<void> enterCredentials() async {
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'a-long passphrase',
      );
    }

    await enterCredentials();
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await enterCredentials();
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('No attractions found'), findsOneWidget);
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    await enterCredentials();
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Travel Preferences'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });
}
