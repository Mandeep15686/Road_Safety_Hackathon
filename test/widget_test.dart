import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crash_guard/core/widgets/connectivity_banner.dart';

void main() {
  testWidgets('OfflineReadyBanner shows child', (WidgetTester tester) async {
    // The OfflineReadyBanner does NOT require a ProviderScope since it's a StatelessWidget
    // but OfflineChip might be used elsewhere.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OfflineReadyBanner(
            child: Scaffold(body: Text('Test Content')),
          ),
        ),
      ),
    );

    expect(find.text('Test Content'), findsOneWidget);
  });
}
