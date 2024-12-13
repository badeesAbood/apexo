import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/backend/observable/observable.dart';

class TestObservable extends ObservableBase {
  int count = 1;
  void trigger() {
    count = count + 1;
    notifyObservers([OEvent.modify("count")]);
  }
}

final TestObservable target = TestObservable();

class TestObservingWidget extends ObservingWidget {
  const TestObservingWidget({super.key});

  @override
  List<ObservableBase> getObservableState() => [target];

  @override
  Widget build(BuildContext context) {
    return SizedBox(child: Text(target.count.toString()));
  }
}

void main() {
  group("Observing Widget", () {
    setUp(() {
      target.count = 1;
    });

    testWidgets('ObservingWidget rebuilds when observable changes', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestObservingWidget(),
      ));

      // Initial build
      expect(find.widgetWithText(SizedBox, "1"), findsOneWidget);

      // Trigger observable change
      target.trigger();
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SizedBox, "2"), findsOneWidget);
    });

    testWidgets('ObservingWidget does not rebuild when disposed', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestObservingWidget(),
      ));

      // Initial build
      expect(find.widgetWithText(SizedBox, "1"), findsOneWidget);

      // Trigger observable change
      target.trigger();
      await tester.pumpAndSettle();

      expect(find.widgetWithText(SizedBox, "2"), findsOneWidget);

      expect(target.observers.length, equals(1));
      // Dispose widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      expect(target.observers.length, equals(0));
    });

    testWidgets('ObservingWidget rebuilds correctly after multiple changes', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestObservingWidget(),
      ));

      // Initial build
      expect(find.widgetWithText(SizedBox, "1"), findsOneWidget);

      // Trigger multiple observable changes
      target.trigger();
      target.trigger();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SizedBox, "3"), findsOneWidget);
    });

    testWidgets('ObservingWidget does not rebuild if no changes', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestObservingWidget(),
      ));

      // Initial build
      expect(find.widgetWithText(SizedBox, "1"), findsOneWidget);

      // No changes to observable
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SizedBox, "1"), findsOneWidget);
    });

    testWidgets('ObservingWidget displays correct initial state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestObservingWidget(),
      ));

      // Initial build
      expect(find.widgetWithText(SizedBox, "1"), findsOneWidget);
    });
  });
}
