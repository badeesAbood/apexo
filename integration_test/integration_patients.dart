import 'package:apexo/common_widgets/item_title.dart';
import 'package:apexo/common_widgets/datatable.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/test_utils.dart';
import 'base.dart';

class PatientsIntegrationTest extends IntegrationTestBase {
  PatientsIntegrationTest({required super.tester});

  @override
  String get name => 'patients';

  final List<List<String>> patientsFirstSet = [
    ["Alawi", "1992", "Mosul", "ali@gmail.com", "♂️ Male", "111111111111", "He is parent", "parent"],
    ["Dandoon", "1993", "Kirkuk", "dina@gmail.com", "♀️ Female", "222222222222", "She is parent", "parent"],
  ];

  final List<List<String>> patientsSecondSet = [
    ["Yousif", "2021", "Mosul", "yousif@gmail.com", "♂️ Male", "333333333333", "He is a son", "son"],
    ["Shams", "2023", "Mosul", "shams@gmail.com", "♀️ Female", "444444444444", "She is a daughter", "daughter"],
  ];

  final List<String> patientsThirdSet = [
    "John",
    "Adam",
    "Leonard",
    "Alice",
    "Rita",
    "Will",
    "David",
    "Debra",
    "Ellie",
    "Cynthia",
    "Tom",
    "Bill",
    "Rich",
    "Don",
    "Ryan",
    "Michael",
    "Fred",
    "George",
    "Elizabeth",
    "Edward",
    "Jim",
    "Tabitha",
    "Neil",
    "Eddie",
    "Jane",
    "Jack",
    "Jimmy",
    "Tim",
    "Timmy",
    "Ron",
    "Dylan",
    "Tony",
    "William",
    "Vlad",
    "Debra",
    "Michelle"
  ];

  List<String> getOrderedPatientNames() {
    return find.byType(ItemTitle).evaluate().map((e) => e.widget as ItemTitle).map((e) => e.item.title).toList();
  }

  @override
  Map<String, Future<Null> Function()> get tests => {
        '01: Move to patients page++': () async {
          await tester.tap(find.byKey(const Key('patients_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.patientsScreen), findsOneWidget);
        },
        "02: should add patients++": () async {
          for (var patient in patientsFirstSet) {
            await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
            await tester.pumpAndSettle();
            await tester.enterText(find.byKey(WK.fieldPatientName), patient[0]);
            await tester.enterText(find.byKey(WK.fieldPatientYOB), patient[1]);
            await tester.enterText(find.byKey(WK.fieldPatientAddress), patient[2]);
            await tester.enterText(find.byKey(WK.fieldPatientEmail), patient[3]);
            await tester.tap(find.byKey(WK.fieldPatientGender));
            await tester.pumpAndSettle();
            await tester.tap(find
                .descendant(of: find.byType(Overlay), matching: find.widgetWithText(ComboBoxItem<int>, patient[4]))
                .first);
            await tester.pumpAndSettle();
            await tester.enterText(find.byKey(WK.fieldPatientPhone), patient[5]);
            await tester.enterText(find.byKey(WK.fieldPatientNotes), patient[6]);
            await tester.enterText(find.byKey(WK.fieldPatientTags), patient[7]);
            await tester.pumpAndSettle();
            await TestUtils.tapFromTagInput(tester, patient[7]);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Save'));
            await tester.pumpAndSettle();
            expect(find.widgetWithText(ItemTitle, patient[0]), findsOneWidget);
          }
        },
        "02: should add patients (2)": () async {
          for (var patient in patientsSecondSet) {
            await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
            await tester.pumpAndSettle();
            await tester.enterText(find.byKey(WK.fieldPatientName), patient[0]);
            await tester.enterText(find.byKey(WK.fieldPatientYOB), patient[1]);
            await tester.enterText(find.byKey(WK.fieldPatientAddress), patient[2]);
            await tester.enterText(find.byKey(WK.fieldPatientEmail), patient[3]);
            await tester.tap(find.byKey(WK.fieldPatientGender));
            await tester.pumpAndSettle();
            await tester.tap(find
                .descendant(of: find.byType(Overlay), matching: find.widgetWithText(ComboBoxItem<int>, patient[4]))
                .first);
            await tester.pumpAndSettle();
            await tester.enterText(find.byKey(WK.fieldPatientPhone), patient[5]);
            await tester.enterText(find.byKey(WK.fieldPatientNotes), patient[6]);
            await tester.enterText(find.byKey(WK.fieldPatientTags), patient[7]);
            await tester.pumpAndSettle();
            await TestUtils.tapFromTagInput(tester, patient[7]);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Save'));
            await tester.pumpAndSettle();
            expect(find.widgetWithText(ItemTitle, patient[0]), findsOneWidget);
          }
        },
        "03: Filtering by pills": () async {
          await tester.tap(find.byKey(const Key('doctors_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.doctorsScreen), findsOneWidget);

          await tester.tap(find.byKey(const Key('patients_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.patientsScreen), findsOneWidget);

          await tester.tap(find.widgetWithText(DataTablePill, "parent").first);
          await tester.pumpAndSettle();

          expect(find.widgetWithText(ItemTitle, "Alawi"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Yousif"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Shams"), findsNothing);
          expect(find.descendant(of: find.byType(CupertinoTextField), matching: find.text("parent")), findsOneWidget);
          expect(
            find.descendant(
              of: find.widgetWithText(DataTablePill, "parent"),
              matching: find.byIcon(FluentIcons.check_mark),
            ),
            findsNWidgets(2),
          );

          await tester.tap(find.widgetWithText(DataTablePill, "parent").first);
          await tester.pumpAndSettle();

          expect(find.widgetWithText(ItemTitle, "Alawi"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Yousif"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Shams"), findsOneWidget);
          expect(find.descendant(of: find.byType(CupertinoTextField), matching: find.text("parent")), findsNothing);
          expect(
            find.descendant(
              of: find.widgetWithText(DataTablePill, "parent"),
              matching: find.byIcon(FluentIcons.check_mark),
            ),
            findsNWidgets(0),
          );

          await tester.tap(find.widgetWithText(DataTablePill, "son"));
          await tester.pumpAndSettle();

          expect(find.widgetWithText(ItemTitle, "Alawi"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Yousif"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Shams"), findsNothing);
          expect(find.descendant(of: find.byType(CupertinoTextField), matching: find.text("son")), findsOneWidget);
          expect(
            find.descendant(
              of: find.widgetWithText(DataTablePill, "son"),
              matching: find.byIcon(FluentIcons.check_mark),
            ),
            findsNWidgets(1),
          );

          await tester.tap(find.widgetWithText(DataTablePill, "son"));
          await tester.pumpAndSettle();

          expect(find.widgetWithText(ItemTitle, "Alawi"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Yousif"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Shams"), findsOneWidget);
          expect(find.descendant(of: find.byType(CupertinoTextField), matching: find.text("son")), findsNothing);
          expect(
            find.descendant(
              of: find.widgetWithText(DataTablePill, "son"),
              matching: find.byIcon(FluentIcons.check_mark),
            ),
            findsNWidgets(0),
          );

          await tester.tap(find.widgetWithText(DataTablePill, "daughter"));
          await tester.pumpAndSettle();

          expect(find.widgetWithText(ItemTitle, "Alawi"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Yousif"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Shams"), findsOneWidget);
          expect(find.descendant(of: find.byType(CupertinoTextField), matching: find.text("daughter")), findsOneWidget);
          expect(
            find.descendant(
              of: find.widgetWithText(DataTablePill, "daughter"),
              matching: find.byIcon(FluentIcons.check_mark),
            ),
            findsNWidgets(1),
          );

          await tester.tap(find.widgetWithText(DataTablePill, "daughter"));
          await tester.pumpAndSettle();

          expect(find.widgetWithText(ItemTitle, "Alawi"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Yousif"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Shams"), findsOneWidget);
          expect(find.descendant(of: find.byType(CupertinoTextField), matching: find.text("daughter")), findsNothing);
          expect(
            find.descendant(
              of: find.widgetWithText(DataTablePill, "daughter"),
              matching: find.byIcon(FluentIcons.check_mark),
            ),
            findsNWidgets(0),
          );
        },
        "04: Sorting Items: Assert initial order by title": () async {
          expect(getOrderedPatientNames().toString(), ["Alawi", "Dandoon", "Shams", "Yousif"].toString());
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Yousif", "Shams", "Dandoon", "Alawi"].toString());
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Alawi", "Dandoon", "Shams", "Yousif"].toString());
        },
        "05: Sort by gender": () async {
          await tester.tap(find.byKey(WK.dataTableSortBy));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ComboBoxItem<int>, "By Gender"));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Shams", "Dandoon", "Yousif", "Alawi"].toString());
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Yousif", "Alawi", "Shams", "Dandoon"].toString());
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Shams", "Dandoon", "Yousif", "Alawi"].toString());
        },
        "06: Sort by age": () async {
          await tester.tap(find.byKey(WK.dataTableSortBy));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ComboBoxItem<int>, "By Age"));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Shams", "Yousif", "Dandoon", "Alawi"].toString());
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Alawi", "Dandoon", "Yousif", "Shams"].toString());
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          expect(getOrderedPatientNames().toString(), ["Shams", "Yousif", "Dandoon", "Alawi"].toString());
        },
        "07: Adding many more patients": () async {
          for (var name in patientsThirdSet) {
            await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
            await tester.pumpAndSettle();
            await tester.enterText(find.byKey(WK.fieldPatientName), name);
            await tester.tap(find.text('Save'));
            await tester.pumpAndSettle();
          }
          expect(find.text("Showing 10/40"), findsOneWidget);
        },
        "08: Show more": () async {
          await tester.drag(find.byKey(WK.dataTableListView), const Offset(0, -500));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(FluentIcons.double_chevron_down));
          await tester.pumpAndSettle();
          await tester.drag(find.byKey(WK.dataTableListView), const Offset(0, 500));
          await tester.pumpAndSettle();
          expect(find.text("Showing 20/40"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Alawi"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsNothing);
          expect(getOrderedPatientNames().first, "Shams");
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, "Alawi"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Dandoon"), findsOneWidget);
          expect(getOrderedPatientNames().first, "Alawi");
          await tester.drag(find.byKey(WK.dataTableListView), const Offset(0, -1500));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(FluentIcons.double_chevron_down));
          await tester.pumpAndSettle();
          expect(find.text("Showing 30/40"), findsOneWidget);
          await tester.drag(find.byKey(WK.dataTableListView), const Offset(0, -1500));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(FluentIcons.double_chevron_down));
          await tester.pumpAndSettle();
          expect(find.text("Showing 40/40"), findsOneWidget);
          await tester.drag(find.byKey(WK.dataTableListView), const Offset(0, 3000));
        }
      };
}
