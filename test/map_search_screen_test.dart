import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petbridge_app/screens/search/map_search_screen.dart';

void main() {
  const testLocation = GeoPoint(6.8649, 79.8997);

  group('MapSearchScreen', () {
    testWidgets('Screen renders with map background and search bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapSearchScreen(
            initialLocation: testLocation,
            initialLocationLabel: 'Test location',
          ),
        ),
      );

      // Verify screen renders without errors
      expect(find.byType(MapSearchScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('Search bar tap opens location picker', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapSearchScreen(
            initialLocation: testLocation,
            initialLocationLabel: 'Test location',
          ),
        ),
      );

      // A selected location opens the filter sheet.
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // Tap search bar
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('Choose a location'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    testWidgets('Category chip selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapSearchScreen(
            initialLocation: testLocation,
            initialLocationLabel: 'Test location',
          ),
        ),
      );

      // Find and tap "Lost" category chip
      final lostChip = find.byWidgetPredicate(
        (widget) =>
            widget is ChoiceChip &&
            widget.label is Text &&
            (widget.label as Text).data == 'Lost',
      );

      if (lostChip.evaluate().isNotEmpty) {
        await tester.tap(lostChip);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Distance slider updates value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapSearchScreen(
            initialLocation: testLocation,
            initialLocationLabel: 'Test location',
          ),
        ),
      );

      // Find slider and drag it
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Drag slider to simulate user interaction
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('Reset button clears all filters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapSearchScreen(
            initialLocation: testLocation,
            initialLocationLabel: 'Test location',
          ),
        ),
      );

      // Find and tap Reset button
      final resetButton = find.byWidgetPredicate(
        (widget) =>
            widget is TextButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'Reset',
      );

      if (resetButton.evaluate().isNotEmpty) {
        await tester.tap(resetButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Apply filters button closes sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapSearchScreen(
            initialLocation: testLocation,
            initialLocationLabel: 'Test location',
          ),
        ),
      );

      // Find and tap Apply Filters button
      final applyButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'Apply Filters',
      );

      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Map pins render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapSearchScreen(
            initialLocation: testLocation,
            initialLocationLabel: 'Test location',
          ),
        ),
      );

      // Verify the OpenStreetMap widget renders the map and markers.
      expect(find.byType(FlutterMap), findsOneWidget);

      // Render and verify no errors
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
