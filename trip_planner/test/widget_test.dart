import 'package:flutter_test/flutter_test.dart';
import 'package:trip_planner/main.dart'; // make sure path is correct

void main() {
  testWidgets('App loads HomeScreen', (WidgetTester tester) async {
    // Use the correct class name here
    await tester.pumpWidget(const TripPlannerApp());

    // Check if HomeScreen title exists
    expect(find.text('Trip Planner'), findsOneWidget);
  });
}
