import 'package:apexo/services/localization/index.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/common_widgets/acrylic_title.dart';
import 'package:apexo/common_widgets/date_time_picker.dart';
import 'package:apexo/features/appointments/calendar_widget.dart';
import 'package:apexo/features/appointments/appointment_model.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import '../test/test_utils.dart';
import 'base.dart';

class CalendarIntegrationTest extends IntegrationTestBase {
  CalendarIntegrationTest({required super.tester});

  @override
  String get name => 'calendar';

  @override
  Map<String, Future<Null> Function()> get tests => {
        "01: Should move to calendar page": () async {
          await tester.tap(find.byKey(const Key('calendar_screen_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('calendar_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.calendarScreen), findsOneWidget);
          expect(find.text(DateFormat("dd MMMM / yyyy").format(DateTime.now())), findsOneWidget);
        },
        "02: add button should work": () async {
          await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
          await tester.pumpAndSettle();
          expect(find.text("New Patient"), findsOneWidget);
          await TestUtils.inputTag(tester, WK.fieldPatient, "Alawi", "ala");
          await tester.pumpAndSettle();
          expect(find.text("New Patient"), findsNothing);
          await TestUtils.inputTag(tester, WK.fieldOperators, "Ali A. Saleem", "ali");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Time"));
          await tester.pumpAndSettle();
          await TestUtils.enterTime(tester, 1, 30, true);
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPreOpNotes), "this: 1:30");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Save"));
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
          await tester.pumpAndSettle();
          expect(find.text("New Patient"), findsOneWidget);
          await TestUtils.inputTag(tester, WK.fieldPatient, "Alawi", "ala");
          await tester.pumpAndSettle();
          expect(find.text("New Patient"), findsNothing);
          await TestUtils.inputTag(tester, WK.fieldOperators, "Ali A. Saleem", "ali");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Time"));
          await tester.pumpAndSettle();
          await TestUtils.enterTime(tester, 1, 15, true);
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPreOpNotes), "this: 1:15");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Save"));
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
          await tester.pumpAndSettle();
          expect(find.text("New Patient"), findsOneWidget);
          await TestUtils.inputTag(tester, WK.fieldPatient, "Alawi", "ala");
          await tester.pumpAndSettle();
          expect(find.text("New Patient"), findsNothing);
          await TestUtils.inputTag(tester, WK.fieldOperators, "Alia A. Saleem", "ali");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Time"));
          await tester.pumpAndSettle();
          await TestUtils.enterTime(tester, 5, 30, true);
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPreOpNotes), "this: 5:30");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Save"));
          await tester.pumpAndSettle();
        },
        "03: appointments should be sorted according to their time of day": () async {
          final tiles = find
              .byKey(WK.calendarAppointmentTile)
              .evaluate()
              .map((e) => e.widget as AppointmentCalendarTile)
              .map((e) => (e.item as Appointment).preOpNotes)
              .toList();

          expect(tiles, [
            "this: 1:15",
            "this: 1:30",
            "this: 5:30",
          ]);
        },
        "04: When coming back to calendar the selected date resets to today": () async {
          final days = find.byType(DayCell);
          expect(days, findsNWidgets(7));
          for (var i = 0; i < 7; i++) {
            final targetCell = days.at(i);
            final targetCellWidget = targetCell.evaluate().first.widget as DayCell;
            if (targetCellWidget.day.toIso8601String().split("T")[0] !=
                DateTime.now().toIso8601String().split("T")[0]) {
              await tester.tap(targetCell);
              await tester.pumpAndSettle();
              final selected = targetCellWidget.day;
              expect(find.text(DateFormat("dd MMMM / yyyy").format(selected)), findsOneWidget);
              break;
            }
          }
          await tester.tap(find.byKey(const Key('doctors_screen_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('calendar_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.calendarScreen), findsOneWidget);
          expect(find.text(DateFormat("dd MMMM / yyyy").format(DateTime.now())), findsOneWidget);
        },
        "05: Selecting a date should be reflected on title bar and 'Add'": () async {
          final days = find.byType(DayCell);
          expect(days, findsNWidgets(7));
          for (var i = 0; i < 7; i++) {
            final targetCell = days.at(i);
            final targetCellWidget = targetCell.evaluate().first.widget as DayCell;
            await tester.tap(targetCell);
            await tester.pumpAndSettle();
            final selected = targetCellWidget.day;
            expect(find.text(DateFormat("dd MMMM / yyyy").format(selected)), findsOneWidget);
            await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
            await tester.pumpAndSettle();
            expect(find.widgetWithText(DateTimePicker, DateFormat("d MMMM yyyy").format(selected)), findsOneWidget);
            await TestUtils.actionOnModal(tester, pages.openAppointment.id, "Cancel");
            await tester.pumpAndSettle();

            if (targetCellWidget.day.toIso8601String().split("T")[0] ==
                DateTime.now().toIso8601String().split("T")[0]) {
              expect(find.text('Today'), findsNothing);
            } else {
              expect(find.text('Today'), findsOneWidget);
              await tester.tap(find.text('Today'));
              await tester.pumpAndSettle();
              expect(find.text('Today'), findsNothing);
              expect(find.text(DateFormat("dd MMMM / yyyy").format(DateTime.now())), findsOneWidget);
            }
          }
          await tester.pumpAndSettle();
        },
        "06: display notice if the selected date has no appointments": () async {
          expect(find.text(txt("noAppointmentsForThisDay")), findsNothing);
          expect(find.byIcon(FluentIcons.clock), findsNWidgets(3));
          final days = find.byType(DayCell);
          expect(days, findsNWidgets(7));
          for (var i = 0; i < 7; i++) {
            final targetCell = days.at(i);
            final targetCellWidget = targetCell.evaluate().first.widget as DayCell;
            if (targetCellWidget.day.toIso8601String().split("T")[0] !=
                DateTime.now().toIso8601String().split("T")[0]) {
              await tester.tap(targetCell);
              await tester.pumpAndSettle();
              final selected = targetCellWidget.day;
              expect(find.text(DateFormat("dd MMMM / yyyy").format(selected)), findsOneWidget);
              break;
            }
          }
          expect(find.text(txt("noAppointmentsForThisDay")), findsOneWidget);
        },
        "07: an indicator of the number of appointments should be visible": () async {
          expect(find.byType(AppointmentsNumberIndicator), findsOneWidget);
          expect(find.widgetWithText(AppointmentsNumberIndicator, "3"), findsOneWidget);
        },
        "08: by default the selected calendar is week": () async {
          expect(find.widgetWithText(GestureDetector, 'W'), findsOneWidget);
          await tester.tap(find.widgetWithText(GestureDetector, 'W'));
          await tester.pumpAndSettle();
          final days1 = find.byType(DayCell);
          expect(days1, findsNWidgets(14));
          expect(find.widgetWithText(GestureDetector, '2W'), findsOneWidget);
          await tester.tap(find.widgetWithText(GestureDetector, '2W'));
          await tester.pumpAndSettle();
          final days2 = find.byType(DayCell);
          expect(days2, findsAtLeast(30));
          expect(find.widgetWithText(GestureDetector, 'M'), findsOneWidget);
          await tester.tap(find.widgetWithText(GestureDetector, 'M'));
          await tester.pumpAndSettle();
        },
        "09: Calendar tiles": () async {
          // just to reset the selected date to today
          await tester.tap(find.byKey(const Key('doctors_screen_button')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('calendar_screen_button')));
          await tester.pumpAndSettle();

          final tiles = find.byKey(WK.calendarAppointmentTile);
          expect(
              find.descendant(of: tiles.at(0), matching: find.widgetWithText(IconButton, '01:15 AM')), findsOneWidget);
          expect(
              find.descendant(of: tiles.at(1), matching: find.widgetWithText(IconButton, '01:30 AM')), findsOneWidget);
          expect(
              find.descendant(of: tiles.at(2), matching: find.widgetWithText(IconButton, '05:30 AM')), findsOneWidget);

          await tester.tap(find.descendant(of: tiles.at(2), matching: find.widgetWithText(IconButton, '05:30 AM')));
          await tester.pumpAndSettle();
          await TestUtils.enterTime(tester, 7, 10, false);
          await tester.pumpAndSettle();
          expect(find.descendant(of: tiles.at(2), matching: find.widgetWithText(IconButton, '05:30 AM')), findsNothing);
          expect(
              find.descendant(of: tiles.at(2), matching: find.widgetWithText(IconButton, '07:10 PM')), findsOneWidget);

          expect(find.descendant(of: tiles.at(0), matching: find.widgetWithText(ItemTitle, "Alawi")), findsOneWidget);
          await tester.tap(find.descendant(of: tiles.at(0), matching: find.byType(ListTile)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Alawi_clear')));
          await tester.pumpAndSettle();
          await TestUtils.inputTag(tester, WK.fieldPatient, "Dandoon", "dan");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, pages.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.descendant(of: tiles.at(0), matching: find.widgetWithText(ItemTitle, "Dandoon")), findsOneWidget);
          expect(find.textContaining("Ali A."), findsNWidgets(2));
          expect(find.textContaining("Alia A."), findsOneWidget);
          await tester.tap(find.descendant(of: tiles.at(0), matching: find.byType(Checkbox)));
          await tester.pumpAndSettle();
          expect(find.descendant(of: tiles.at(0), matching: find.text("✔️ this: 1:15")), findsOneWidget);

          await tester.tap(find.descendant(of: tiles.at(0), matching: find.byType(ListTile)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPostOpNotes), "some post operative details");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, pages.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(
              find.descendant(of: tiles.at(0), matching: find.text("✔️ some post operative details")), findsOneWidget);
        },
        "10: filtering by doctor": () async {
          expect(find.widgetWithText(ComboBoxItem<String>, txt("allDoctors")), findsOneWidget);
          await tester.tap(find.widgetWithText(ComboBoxItem<String>, txt("allDoctors")));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ComboBoxItem<String>, "Ali A. Saleem"), findsOneWidget);
          await tester.tap(find.widgetWithText(ComboBoxItem<String>, "Ali A. Saleem"));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.calendarAppointmentTile), findsNWidgets(2));
          expect(find.textContaining("Ali A."), findsAtLeastNWidgets(2));
          expect(find.textContaining("Alia A."), findsNothing);
        },
      };
}
