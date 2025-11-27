// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:collaborative_whiteboard/main.dart';

void main() {
	testWidgets('Dashboard loads with presentation controls', (WidgetTester tester) async {
		await tester.pumpWidget(const MyApp());

		// The offline dashboard should render immediately with the presentation title and actions.
		expect(find.text('Presentation Whiteboard'), findsOneWidget);
		expect(find.text('New Presentation'), findsOneWidget);
		expect(find.byIcon(Icons.add), findsOneWidget);

		// When there are no presentations yet, an empty state should be shown.
		expect(find.text('No presentations yet'), findsOneWidget);
		expect(find.text('Create Presentation'), findsOneWidget);
	});
}
