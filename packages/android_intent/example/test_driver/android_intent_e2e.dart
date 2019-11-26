import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:android_intent_example/main.dart';
import 'package:e2e/e2e.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// This is a smoke test that verifies that the example app builds and loads.
/// Because this plugin works by launching Android platform UIs it's not
/// possible to meaningfully test it through its Dart interface currently. There
/// are more useful unit tests for the platform logic under android/src/test/.
void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Embedding example app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the new embedding example app builds
    if (Platform.isAndroid) {
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Text && widget.data.startsWith('Tap here'),
        ),
        findsNWidgets(2),
      );
    } else {
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Text &&
              widget.data.startsWith('This plugin only works with Android'),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('#launch throws when no Activity is found',
      (WidgetTester tester) async {
    // We can't test that any of this is really working, this is mostly just
    // checking that the plugin API is registered. Only works on Android.
    const AndroidIntent intent =
        AndroidIntent(action: 'LAUNCH', package: 'foobar');
    await expectLater(() async => await intent.launch(), throwsA((Exception e) {
      return e is PlatformException &&
          e.message.contains('No Activity found to handle Intent');
    }));
  }, skip: !Platform.isAndroid);
}
