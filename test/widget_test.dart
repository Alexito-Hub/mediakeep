import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mediakeep/main.dart';

void main() {
  testWidgets('App mounts without errors', (WidgetTester tester) async {
    // Provide empty SharedPreferences so services don't throw
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DownloaderApp(hasCompletedOnboarding: true));

    // The app should render at least one widget
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
