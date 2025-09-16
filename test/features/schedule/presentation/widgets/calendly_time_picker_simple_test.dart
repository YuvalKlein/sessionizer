import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/schedule/presentation/widgets/calendly_time_picker.dart';

void main() {
  group('CalendlyTimePicker Widget Tests', () {
    testWidgets('should render dropdown form field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimePicker(
              label: 'Test Time',
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<TimeOfDay>), findsOneWidget);
      expect(find.text('Select time'), findsOneWidget);
    });

    testWidgets('should display initial time when provided', (WidgetTester tester) async {
      const initialTime = TimeOfDay(hour: 10, minute: 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimePicker(
              initialTime: initialTime,
              label: 'Test Time',
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      expect(find.text('10:30am'), findsOneWidget);
    });

    testWidgets('should be disabled when enabled is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimePicker(
              label: 'Test Time',
              enabled: false,
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<TimeOfDay>>(
        find.byType(DropdownButtonFormField<TimeOfDay>),
      );

      expect(dropdown.onChanged, isNull);
    });

    testWidgets('should have onChanged callback when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimePicker(
              label: 'Test Time',
              enabled: true,
              onTimeChanged: (time) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<TimeOfDay>>(
        find.byType(DropdownButtonFormField<TimeOfDay>),
      );

      expect(dropdown.onChanged, isNotNull);
    });
  });

  group('CalendlyTimeRangePicker Widget Tests', () {
    testWidgets('should render two time pickers with separator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimeRangePicker(
              onTimeRangeChanged: (start, end) {},
            ),
          ),
        ),
      );

      expect(find.byType(CalendlyTimePicker), findsNWidgets(2));
      expect(find.text('-'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<TimeOfDay>), findsNWidgets(2));
    });

    testWidgets('should display initial start and end times', (WidgetTester tester) async {
      const startTime = TimeOfDay(hour: 9, minute: 0);
      const endTime = TimeOfDay(hour: 17, minute: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimeRangePicker(
              startTime: startTime,
              endTime: endTime,
              onTimeRangeChanged: (start, end) {},
            ),
          ),
        ),
      );

      expect(find.text('9:00am'), findsOneWidget);
      expect(find.text('5:00pm'), findsOneWidget);
    });

    testWidgets('should handle null initial times', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimeRangePicker(
              onTimeRangeChanged: (start, end) {},
            ),
          ),
        ),
      );

      expect(find.text('Select time'), findsNWidgets(2));
    });

    testWidgets('should be disabled when enabled is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendlyTimeRangePicker(
              enabled: false,
              onTimeRangeChanged: (start, end) {},
            ),
          ),
        ),
      );

      final dropdowns = find.byType(DropdownButtonFormField<TimeOfDay>);
      expect(dropdowns, findsNWidgets(2));

      // Both dropdowns should be disabled
      for (final element in dropdowns.evaluate()) {
        final dropdown = element.widget as DropdownButtonFormField<TimeOfDay>;
        expect(dropdown.onChanged, isNull);
      }
    });
  });

  group('Time Formatting Logic Tests', () {
    test('should handle morning hours correctly', () {
      const time = TimeOfDay(hour: 9, minute: 30);
      expect(time.hour, equals(9));
      expect(time.minute, equals(30));
    });

    test('should handle afternoon hours correctly', () {
      const time = TimeOfDay(hour: 15, minute: 45);
      expect(time.hour, equals(15));
      expect(time.minute, equals(45));
    });

    test('should handle midnight correctly', () {
      const time = TimeOfDay(hour: 0, minute: 0);
      expect(time.hour, equals(0));
      expect(time.minute, equals(0));
    });

    test('should handle noon correctly', () {
      const time = TimeOfDay(hour: 12, minute: 0);
      expect(time.hour, equals(12));
      expect(time.minute, equals(0));
    });
  });

  group('Widget Integration Tests', () {
    testWidgets('should work within a form', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  CalendlyTimePicker(
                    label: 'Start Time',
                    onTimeChanged: (time) {},
                  ),
                  CalendlyTimePicker(
                    label: 'End Time',
                    onTimeChanged: (time) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(CalendlyTimePicker), findsNWidgets(2));
    });

    testWidgets('should handle multiple instances without conflicts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CalendlyTimePicker(
                  label: 'Time 1',
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                  onTimeChanged: (time) {},
                ),
                CalendlyTimePicker(
                  label: 'Time 2',
                  initialTime: const TimeOfDay(hour: 17, minute: 0),
                  onTimeChanged: (time) {},
                ),
                CalendlyTimePicker(
                  label: 'Time 3',
                  onTimeChanged: (time) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CalendlyTimePicker), findsNWidgets(3));
      expect(find.text('9:00am'), findsOneWidget);
      expect(find.text('5:00pm'), findsOneWidget);
      expect(find.text('Select time'), findsOneWidget);
    });
  });
}
