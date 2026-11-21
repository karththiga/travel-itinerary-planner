import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/app/travel_app.dart';
import 'package:mobile/features/preferences/presentation/preference_screen.dart';
import 'package:mobile/app/splash_screen.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final expired in [true, false]) {
    testWidgets(
      'Removed session returns to login (locally expired: $expired)',
      (tester) async {
        const storage = FlutterSecureStorage();
        await storage.write(
          key: 'explorelanka.session',
          value: jsonEncode({
            'token': 'previous-token',
            'expiresAt': DateTime.now()
                .add(Duration(hours: expired ? -1 : 1))
                .toIso8601String(),
          }),
        );
        var requests = 0;
        final client = MockClient((request) async {
          requests++;
          expect(request.url.path, '/api/auth/me');
          expect(request.headers['authorization'], 'Bearer previous-token');
          return http.Response('', 401);
        });
        addTearDown(client.close);
        await tester.pumpWidget(TravelApp(client: client));
        await tester.pump(SplashScreen.duration);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
        expect(requests, expired ? 0 : 1);
        expect(await storage.read(key: 'explorelanka.session'), isNull);
      },
    );
  }

  testWidgets('Forgot password requests a code and returns to login', (
    tester,
  ) async {
    final requests = <String>[];
    const code = 'abcdefghijklmnopqrstuvwxyz123456';
    final client = MockClient((request) async {
      requests.add(request.url.path);
      final fields = jsonDecode(request.body);
      if (request.url.path.endsWith('/forgot-password')) {
        expect(fields, {'email': 'traveler@example.com'});
        return http.Response('', 202);
      }
      expect(fields, {
        'email': 'traveler@example.com',
        'code': code,
        'password': 'newTravel99',
      });
      return http.Response('', 204);
    });
    addTearDown(client.close);
    await tester.pumpWidget(TravelApp(client: client));
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    Future<void> press(String label) async {
      final button = find.text(label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);
    await tester.enterText(field('Email'), 'traveler@example.com');
    await press('Forgot password?');
    await press('Send reset code');
    await tester.enterText(field('Reset code'), code);
    await tester.enterText(field('New password'), 'newTravel99');
    await tester.enterText(field('Confirm new password'), 'mismatch');
    await press('Update password');
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(requests, ['/api/auth/forgot-password']);
    await tester.enterText(field('Confirm new password'), 'newTravel99');
    await press('Update password');
    expect(requests, ['/api/auth/forgot-password', '/api/auth/reset-password']);
    expect(
      find.text('Password updated. Sign in with your new password.'),
      findsOneWidget,
    );
  });

  testWidgets('Signup and login lead to home and logout returns to login', (
    tester,
  ) async {
    var signedUp = false;
    var credentials = {'email': 'test@example.com', 'password': 'travel99'};
    var profile = {
      'fullName': 'Amara Perera',
      'phoneNumber': '+94771234567',
      'email': credentials['email']!,
    };
    final bookmarks = <String>{};
    const firstPlace = {
      '_id': '0123456789abcdef01234567',
      'name': 'Delft Island',
      'category': 'Nature',
    };
    const alternatePlace = {
      '_id': '0123456789abcdef01234568',
      'name': 'North Coast',
      'latitude': 9.7,
      'longitude': 80.0,
      'category': 'Nature',
    };
    var recommendationRequests = 0;
    var restoreRequests = 0;
    Map<String, dynamic>? savedTrip;
    Map<String, dynamic> session() => {
      'token': 'token',
      'expiresIn': 3600,
      'user': profile,
    };
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/api/auth/signup':
          expect(jsonDecode(request.body), {
            ...credentials,
            'fullName': 'Amara Perera',
            'phoneNumber': '077 123 4567',
          });
          signedUp = true;
          return http.Response(jsonEncode(session()), 201);
        case '/api/auth/login':
          expect(jsonDecode(request.body), credentials);
          return signedUp
              ? http.Response(jsonEncode(session()), 200)
              : http.Response(
                  jsonEncode({'message': 'Invalid email or password.'}),
                  401,
                );
        case '/api/auth/me':
          expect(request.headers['authorization'], 'Bearer token');
          if (request.method == 'GET') {
            restoreRequests++;
            return restoreRequests == 1
                ? http.Response('', 503)
                : http.Response(jsonEncode({'user': profile}), 200);
          }
          expect(request.method, 'PATCH');
          expect(jsonDecode(request.body), {
            'fullName': 'Amara Silva',
            'phoneNumber': '0712345678',
            'email': 'amara@example.com',
            'currentPassword': 'travel99',
            'newPassword': 'lanka987',
          });
          profile = {
            'fullName': 'Amara Silva',
            'phoneNumber': '+94712345678',
            'email': 'amara@example.com',
          };
          credentials = {'email': profile['email']!, 'password': 'lanka987'};
          return http.Response(jsonEncode({'user': profile}), 200);
        case '/api/auth/me/bookmarks':
          expect(request.headers['authorization'], 'Bearer token');
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({'bookmarks': bookmarks.toList()}),
              200,
            );
          }
          expect(request.method, 'PUT');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final key = body['key'] as String;
          if (body['saved'] == true) {
            bookmarks.add(key);
          } else {
            bookmarks.remove(key);
          }
          return http.Response('', 204);
        case '/api/auth/me/trips':
          expect(request.headers['authorization'], 'Bearer token');
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'trips': [?savedTrip],
              }),
              200,
            );
          }
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['attractionIds'], [alternatePlace['_id']]);
          expect(body['preferences'], {
            'interests': ['Nature'],
            'tripDays': 2,
            'budget': 25000,
            'groupType': 'Family',
            'transport': 'Car',
          });
          savedTrip = {
            'id': 'saved-trip',
            'preferences': body['preferences'],
            'stops': [alternatePlace],
          };
          return http.Response(jsonEncode({'trip': savedTrip}), 200);
        case '/api/auth/me/trips/saved-trip':
          expect(request.method, 'DELETE');
          expect(request.headers['authorization'], 'Bearer token');
          savedTrip = null;
          return http.Response('', 204);
        case '/api/auth/logout':
          expect(request.headers['authorization'], 'Bearer token');
          return http.Response('', 204);
        case '/api/recommendations':
          expect(request.method, 'POST');
          final regenerating = recommendationRequests++ > 0;
          expect(jsonDecode(request.body), {
            'interests': ['Nature'],
            'tripDays': 2,
            'budget': 25000,
            'groupType': 'Family',
            'transport': 'Car',
            'excluded': [if (regenerating) firstPlace['_id']],
            'previous': [],
          });
          return http.Response(
            jsonEncode({
              'recommendations': [
                {
                  'attraction': regenerating ? alternatePlace : firstPlace,
                  'matches': ['Nature'],
                  'discovery': false,
                },
              ],
            }),
            200,
          );
        case '/api/travel-route':
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'attractionIds': [alternatePlace['_id']],
          });
          return http.Response(
            jsonEncode({
              'stops': [alternatePlace],
            }),
            200,
          );
        case '/api/attractions':
          return http.Response(
            '[{"_id":"bridge","name":"Nine Arch Bridge","location":"Ella","category":"History",'
            '"description":"A railway bridge in the highlands.","estimatedVisitDuration":90,'
            '"openingTime":"08:00","closingTime":"17:00","entryFee":450},'
            '{"name":"Galle Lighthouse","district":"Galle","category":"Culture"},'
            '{"name":"Kankesanthurai Beach","aliases":["KKS Beach"],"freeAdmission":true,"district":"Jaffna","category":"Beach"}]',
            200,
          );
        default:
          fail('Unexpected API request: ${request.url}');
      }
    });
    addTearDown(client.close);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(TravelApp(client: client));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();

    Finder tab(String name) => find.widgetWithText(NavigationDestination, name);

    Future<void> selectTab(String name) async {
      await tester.tap(tab(name));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    Future<void> enterCredentials() async {
      await tester.enterText(field('Email'), credentials['email']!);
      await tester.enterText(field('Password'), credentials['password']!);
    }

    Future<void> tapVisible(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await enterCredentials();
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);

    await tapVisible(find.text('Sign up'));
    expect(find.text('Create your account'), findsOneWidget);
    await tester.enterText(field('Full name'), 'Amara Perera');
    await tester.enterText(field('Phone number'), '077 123 4567');
    await enterCredentials();
    await tester.enterText(field('Confirm password'), 'different');
    final createAccount = find.widgetWithText(FilledButton, 'Create account');
    await tapVisible(createAccount);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(signedUp, isFalse);
    await tester.enterText(field('Confirm password'), credentials['password']!);
    await tapVisible(createAccount);
    expect(find.text('Discover Sri Lanka'), findsOneWidget);
    for (final name in ['Home', 'Explore', 'Plan', 'Saved', 'Profile']) {
      expect(tab(name), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Save Sigiriya'));
    await selectTab('Saved');
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text('Sigiriya'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Sigiriya from Saved'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bookmark a destination to find it here.'),
      findsOneWidget,
    );
    await selectTab('Profile');
    expect(find.text('Amara Perera'), findsWidgets);
    await tester.enterText(field('Full name'), 'Amara Silva');
    await tester.enterText(field('Phone number'), '0712345678');
    await tester.enterText(field('Email address'), 'amara@example.com');
    await tester.enterText(field('Current password'), 'travel99');
    await tester.enterText(field('New password'), 'lanka987');
    await tester.enterText(field('Confirm new password'), 'incorrect');
    await tapVisible(find.text('Save changes'));
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.enterText(field('Confirm new password'), 'lanka987');
    await tapVisible(find.text('Save changes'));
    expect(find.text('Profile updated.'), findsOneWidget);
    expect(find.text('Amara Silva'), findsWidgets);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    await enterCredentials();
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    final feed = find.byKey(const ValueKey('home-feed'));
    await tester.drag(feed, const Offset(0, -245));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Nine Arch Bridge'), findsOneWidget);
    expect(find.text('Galle Lighthouse'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'View details'));
    await tester.pumpAndSettle();
    expect(find.text('Attraction details'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wildlife'));
    await tester.pumpAndSettle();
    expect(find.text('Wilpattu National Park'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await selectTab('Explore');
    expect(find.text('Explore Sri Lanka'), findsOneWidget);
    expect(find.text('Galle Lighthouse'), findsOneWidget);
    expect(find.text('Entry · Price not listed'), findsWidgets);
    expect(find.text('Entry · LKR 450.00'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'History'));
    await tester.pumpAndSettle();
    expect(find.text('Galle Lighthouse'), findsNothing);
    expect(find.text('Estimated visit: 1 hr 30 min'), findsOneWidget);
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    expect(find.text('A railway bridge in the highlands.'), findsOneWidget);
    expect(find.text('Opens 08:00 · Closes 17:00'), findsOneWidget);
    expect(find.text('LKR 450.00'), findsOneWidget);
    final save = find.text('Save Attraction');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Remove from Saved'), findsOneWidget);
    expect(bookmarks, {'attraction:bridge'});
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(TravelApp(client: client));
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    expect(find.text('Could not verify your saved sign-in.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(restoreRequests, 2);
    await selectTab('Saved');
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text('Nine Arch Bridge'), findsOneWidget);
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Remove from Saved'));
    await tester.tap(find.text('Remove from Saved'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Nine Arch Bridge'), findsNothing);
    expect(bookmarks, isEmpty);
    await selectTab('Explore');
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Galle Lighthouse'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'KKS Beach');
    await tester.pumpAndSettle();
    expect(find.text('Kankesanthurai Beach'), findsOneWidget);
    expect(find.text('Entry · Free'), findsOneWidget);
    expect(find.text('Galle Lighthouse'), findsNothing);
    final photo = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.semanticLabel == 'Illustration of Kankesanthurai Beach',
      ),
    );
    expect(
      (photo.image as AssetImage).assetName,
      'assets/images/kks-beach.jpg',
    );
    await tester.tap(find.widgetWithText(TextButton, 'View details'));
    await tester.pumpAndSettle();
    expect(find.text('Destination illustration'), findsOneWidget);
    expect(find.text('45–90 min'), findsOneWidget);
    expect(find.text('Before you go'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('KKS Beach'), findsOneWidget);
    expect(find.text('Kankesanthurai Beach'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.drag(feed, const Offset(0, 245));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan My Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Your Trip'), findsOneWidget);
    await tester.tap(find.text('Nature'));
    await tester.tap(find.byTooltip('Add a day'));
    await tester.enterText(
      find.descendant(
        of: find.byType(PreferenceScreen),
        matching: find.byType(TextField),
      ),
      '25,000',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final planScroll = find
        .descendant(
          of: find.byType(PreferenceScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    final family = find.widgetWithText(OutlinedButton, 'Family');
    await tester.scrollUntilVisible(family, 160, scrollable: planScroll);
    await tester.pumpAndSettle();
    await tester.tap(family);
    final car = find.widgetWithText(OutlinedButton, 'Car');
    await tester.scrollUntilVisible(car, 160, scrollable: planScroll);
    await tester.pumpAndSettle();
    await tester.tap(car);
    final preview = find.widgetWithText(FilledButton, 'Find recommendations');
    await tester.scrollUntilVisible(preview, 120, scrollable: planScroll);
    await tester.pumpAndSettle();
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.text('Recommended for You'), findsOneWidget);
    expect(find.text('2 Days'), findsOneWidget);
    expect(find.text('LKR 25000.00'), findsOneWidget);
    expect(find.text('Matches your nature interest'), findsOneWidget);
    await tester.tap(find.byTooltip('Save attraction'));
    await tester.pumpAndSettle();
    expect(bookmarks, contains("attraction:${firstPlace['_id']}"));
    await tester.tap(find.text('Remove suggestion'));
    await tester.pumpAndSettle();
    expect(find.text('Delft Island'), findsNothing);
    await tester.tap(find.text('Regenerate suggestions'));
    await tester.pumpAndSettle();
    expect(find.text('North Coast'), findsOneWidget);
    final createRoute = find.widgetWithText(
      FilledButton,
      'Create My Travel Route',
    );
    await tester.ensureVisible(createRoute);
    await tester.pumpAndSettle();
    await tester.tap(createRoute);
    await tester.pumpAndSettle();
    expect(find.text('Your Sri Lanka Adventure'), findsOneWidget);
    await tester.tap(find.byTooltip('Save trip'));
    await tester.pumpAndSettle();
    expect(savedTrip, isNotNull);
    expect(find.text('North Coast'), findsOneWidget);
    expect(find.text('Day 2 · Free day'), findsOneWidget);
    await tester.tap(find.text('Day 1 · Nature'));
    await tester.pumpAndSettle();
    expect(find.text('Entry · Price not listed'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final fullItinerary = find.widgetWithText(
      FilledButton,
      'View Full Itinerary',
    );
    await tester.ensureVisible(fullItinerary);
    await tester.pumpAndSettle();
    await tester.tap(fullItinerary);
    await tester.pumpAndSettle();
    expect(find.text('My Itinerary'), findsOneWidget);
    expect(find.textContaining('North Coast'), findsOneWidget);
    await tester.tap(find.text('Day 2'));
    await tester.pumpAndSettle();
    expect(find.text('No attractions scheduled for this day.'), findsOneWidget);
    await tester.tap(find.text('Day 1'));
    await tester.pumpAndSettle();
    final mapButton = find.text('View Route on Map');
    await tester.ensureVisible(mapButton);
    await tester.tap(mapButton);
    await tester.pumpAndSettle();
    expect(find.text('Day 1 — Route Preview'), findsOneWidget);
    expect(find.text('North Coast'), findsOneWidget);
    await tester.tap(find.byTooltip('Expand map'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Exit expanded map'), findsOneWidget);
    await tester.tap(find.byTooltip('Reset map view'));
    await tester.tap(find.byTooltip('Exit expanded map'));
    await tester.pumpAndSettle();
    expect(find.text('Stops in order'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Plan Your Trip'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discover Sri Lanka'), findsOneWidget);
    await selectTab('Saved');
    expect(find.text('Saved Trips'), findsOneWidget);
    await tester.tap(find.text('North Coast itinerary'));
    await tester.pumpAndSettle();
    expect(find.text('Your Sri Lanka Adventure'), findsOneWidget);
    expect(find.text('North Coast'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove North Coast itinerary'));
    await tester.pumpAndSettle();
    expect(find.text('North Coast itinerary'), findsNothing);
    expect(savedTrip, isNull);
    await selectTab('Profile');
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(TravelApp(client: client));
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(restoreRequests, 2);
  });
}
