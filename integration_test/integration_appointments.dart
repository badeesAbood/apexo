import 'package:apexo/app/routes.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/common_widgets/acrylic_title.dart';
import 'package:apexo/common_widgets/appointment_card.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import '../test/test_utils.dart';
import 'base.dart';

class AppointmentsIntegrationTest extends IntegrationTestBase {
  AppointmentsIntegrationTest({required super.tester});

  @override
  String get name => 'appointments';

  @override
  Map<String, Future<Null> Function()> get tests => {
        "01: should add bare minimum appointments": () async {
          await tester.enterText(find.byKey(WK.dataTableSearch), "Alawi");
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ItemTitle, "Alawi"));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Appointments_icon')));
          await tester.pumpAndSettle();
          expect(find.text(txt("noAppointmentsFound")), findsOneWidget);
          await tester.tap(find.text('New Appointment'));
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
        },
        "02: Side Icons: done check mark": () async {
          await tester.tap(find.byKey(WK.acCheckBox));
          await tester.pumpAndSettle();
          expect(tester.widget<Checkbox>(find.byKey(WK.acCheckBox)).checked, true);
          await tester.tap(find.text("Save"));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ItemTitle, "Alawi"));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Appointments_icon')));
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(tester.widget<Checkbox>(find.byKey(WK.acCheckBox)).checked, true);
          await tester.tap(find.byKey(WK.acCheckBox));
          await tester.pumpAndSettle();
          expect(tester.widget<Checkbox>(find.byKey(WK.acCheckBox)).checked, false);
        },
        "03: Side Icons: Archived icon": () async {
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Archive");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsNothing);
          await tester
              .tap(find.descendant(of: find.byKey(Key(routes.openPatient.id)), matching: find.byType(ArchiveToggle)));
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(find.descendant(of: find.byKey(WK.acSideIcons), matching: find.byIcon(FluentIcons.archive)),
              findsOneWidget);
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Restore");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          await tester
              .tap(find.descendant(of: find.byKey(Key(routes.openPatient.id)), matching: find.byType(ArchiveToggle)));
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(find.descendant(of: find.byKey(WK.acSideIcons), matching: find.byIcon(FluentIcons.archive)),
              findsNothing);
        },
        "04: Side Icons: Missed": () async {
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Date"));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Previous month'));
          await tester.pumpAndSettle();
          await tester.tap(find.text("1"));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(GestureDetector, 'OK'));
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(
              find.descendant(of: find.byKey(WK.acSideIcons), matching: find.byIcon(FluentIcons.event_date_missed12)),
              findsOneWidget);

          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Date"));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Next month'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Next month'));
          await tester.pumpAndSettle();
          await tester.tap(find.text("1"));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(GestureDetector, 'OK'));
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(
              find.descendant(of: find.byKey(WK.acSideIcons), matching: find.byIcon(FluentIcons.event_date_missed12)),
              findsNothing);
        },
        "05: Side Icons: Payment incomplete": () async {
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPrice), "100");
          await tester.enterText(find.byKey(WK.fieldAppointmentPayment), "50");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(find.descendant(of: find.byKey(WK.acSideIcons), matching: find.byIcon(FluentIcons.money)),
              findsOneWidget);
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPrice), "100");
          await tester.enterText(find.byKey(WK.fieldAppointmentPayment), "100");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(
              find.descendant(of: find.byKey(WK.acSideIcons), matching: find.byIcon(FluentIcons.money)), findsNothing);
        },
        "06: changing date and time": () async {
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          final d = DateTime.now().subtract(const Duration(days: 1));
          await tester.tap(find.text("Change Date"));
          await tester.pumpAndSettle();
          await TestUtils.enterDate(tester, d.year, d.month, d.day);
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Time"));
          await tester.pumpAndSettle();
          await TestUtils.enterTime(tester, 6, 30, true);
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(find.text("${DateFormat("E d/MM yyyy").format(d)} - 06:30 AM"), findsOneWidget);

          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Time"));
          await tester.pumpAndSettle();
          await TestUtils.enterTime(tester, 7, 45, false);
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(find.text("${DateFormat("E d/MM yyyy").format(d)} - 07:45 PM"), findsOneWidget);
        },
        "07: Operators": () async {
          expect(find.text("Doctors"), findsNothing);
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldOperators), "ali");
          await tester.pumpAndSettle();
          await TestUtils.tapFromTagInput(tester, "Ali A. Saleem");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();

          expect(find.text("Doctors"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Ali A. Saleem"), findsOneWidget);

          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldOperators), "ali");
          await tester.pumpAndSettle();
          await TestUtils.tapFromTagInput(tester, "Alia A. Saleem");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.text("Doctors"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Ali A. Saleem"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Alia A. Saleem"), findsOneWidget);

          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('Alia A. Saleem_clear')));
          await tester.tap(find.byKey(const Key('Ali A. Saleem_clear')));

          await tester.enterText(find.byKey(WK.fieldOperators), "din");
          await tester.pumpAndSettle();
          await TestUtils.tapFromTagInput(tester, "Dina Ismail");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");

          await tester.pumpAndSettle();
          expect(find.text("Doctors"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Dina Ismail"), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, "Ali A. Saleem"), findsNothing);
          expect(find.widgetWithText(ItemTitle, "Alia A. Saleem"), findsNothing);
        },
        "08: Pre-op notes": () async {
          expect(find.text("Pre-op notes"), findsNothing);
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPreOpNotes), "test pre-op notes");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.text("Pre-op notes"), findsOneWidget);
          expect(find.text("test pre-op notes"), findsOneWidget);
        },
        "09: Post-op notes": () async {
          expect(find.text("Post-op notes"), findsNothing);
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPostOpNotes), "test operative details");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.text("Post-op notes"), findsOneWidget);
          expect(find.text("test operative details"), findsOneWidget);
        },
        "10: Prescriptions": () async {
          expect(find.text("Prescriptions"), findsNothing);
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          expect(find.text("Print Prescription"), findsNothing);
          await TestUtils.inputTag(tester, WK.fieldAppointmentPrescriptions, "Amoxicillin 500mg");
          await tester.pumpAndSettle();
          expect(find.text("Print Prescription"), findsOneWidget);
          await TestUtils.inputTag(tester, WK.fieldAppointmentPrescriptions, "Paracetamol 500mg");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.text("Prescription"), findsOneWidget);
          expect(find.text("Amoxicillin-500mg\nParacetamol-500mg"), findsOneWidget);
        },
        "11: Prescriptions should auto-complete from other appointments": () async {
          final d = DateTime.now().add(const Duration(days: 1));
          await tester.tap(find.text("New Appointment"));
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Date"));
          await tester.pumpAndSettle();
          await TestUtils.enterDate(tester, d.year, d.month, d.day);
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          expect(find.text("Print Prescription"), findsNothing);
          final asb = find.descendant(
              of: find.byKey(WK.fieldAppointmentPrescriptions), matching: find.byType(AutoSuggestBox<String>));
          await tester.tap(asb);
          await tester.enterText(asb, "amo");
          await tester.pumpAndSettle();
          await TestUtils.tapFromTagInput(tester, "Amoxicillin-500mg");

          await tester.pumpAndSettle();
          expect(find.text("Print Prescription"), findsOneWidget);

          await tester.tap(asb);
          await tester.enterText(asb, "par");
          await tester.pumpAndSettle();
          await TestUtils.tapFromTagInput(tester, "Paracetamol-500mg");
          await tester.pumpAndSettle();
          expect(find.text("Print Prescription"), findsOneWidget);

          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.text("Prescription"), findsNWidgets(2));
          expect(find.text("Amoxicillin-500mg\nParacetamol-500mg"), findsNWidgets(2));
        },
        "13: Time Difference in days": () async {
          expect(find.text("After 1 day"), findsOneWidget);
          await tester.tap(find.byIcon(FluentIcons.edit).at(0));
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Time"));
          await tester.pumpAndSettle();
          await TestUtils.enterTime(tester, 12, 00, true);
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.text("After 2 days"), findsOneWidget);
        },
        "14: Archive the above appointments": () async {
          while (true) {
            await tester.pumpAndSettle();
            final editIcons = find.byIcon(FluentIcons.edit);
            if (editIcons.evaluate().isEmpty) break;
            await tester.tap(editIcons.at(0));
            await tester.pumpAndSettle();
            await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Archive");
            await tester.pumpAndSettle();
          }
          expect(find.byType(AppointmentCard), findsNothing);
        },
        "15: More time difference testing": () async {
          final today = DateTime.now();
          final dates = [
            today.add(const Duration(days: 8)),
            today.subtract(const Duration(days: 9)),
            today.add(const Duration(days: 19)),
            today.subtract(const Duration(days: 10)),
            today.add(const Duration(days: 19)),
            today,
          ];
          for (var date in dates) {
            await tester.tap(find.text("New Appointment"));
            await tester.pumpAndSettle();
            await tester.tap(find.text("Change Date"));
            await tester.pumpAndSettle();
            await TestUtils.enterDate(tester, date.year, date.month, date.day);
            await tester.pumpAndSettle();
            await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
            await tester.pumpAndSettle();
          }
          final diff = find
              .byType(TimeDifference)
              .evaluate()
              .map((e) => e.widget as TimeDifference)
              .map((e) => e.difference)
              .toList();
          expect(
              diff.toString(),
              [
                "After 1 day",
                "After 9 days",
                "After 8 days",
                "After 11 days",
                "After 0 day",
              ].toString());
        },
        "16: Asserting appointments sorting": () async {
          final today = DateTime.now();

          final cards = find
              .byType(AppointmentCard)
              .evaluate()
              .map((e) => e.widget as AppointmentCard)
              .map((e) => e.appointment.date.toIso8601String().split("T").first)
              .toList();

          expect(
              cards.toString(),
              [
                today.subtract(const Duration(days: 10)).toIso8601String().split("T").first,
                today.subtract(const Duration(days: 9)).toIso8601String().split("T").first,
                today.toIso8601String().split("T").first,
                today.add(const Duration(days: 8)).toIso8601String().split("T").first,
                today.add(const Duration(days: 19)).toIso8601String().split("T").first,
                today.add(const Duration(days: 19)).toIso8601String().split("T").first,
              ].toString());
        },
        "17: Archive the above appointments": () async {
          while (true) {
            await tester.pumpAndSettle();
            final editIcons = find.byIcon(FluentIcons.edit);
            if (editIcons.evaluate().isEmpty) break;
            await tester.tap(editIcons.at(0));
            await tester.pumpAndSettle();
            await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Archive");
            await tester.pumpAndSettle();
          }
          expect(find.byType(AppointmentCard), findsNothing);
        },
        "18: Pricing and payment values": () async {
          await tester.tap(find.text("New Appointment"));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPrice), "10");
          await tester.enterText(find.byKey(WK.fieldAppointmentPayment), "5");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(PaymentPill), findsNWidgets(3));
          expect((find.byType(PaymentPill).evaluate().elementAt(0).widget as PaymentPill).title, "Price");
          expect((find.byType(PaymentPill).evaluate().elementAt(0).widget as PaymentPill).amount, "10.0");
          expect((find.byType(PaymentPill).evaluate().elementAt(1).widget as PaymentPill).title, "Paid");
          expect((find.byType(PaymentPill).evaluate().elementAt(1).widget as PaymentPill).amount, "5.0");
          expect((find.byType(PaymentPill).evaluate().elementAt(2).widget as PaymentPill).title, "Underpaid");
          expect((find.byType(PaymentPill).evaluate().elementAt(2).widget as PaymentPill).amount, "5.0");

          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPrice), "10");
          await tester.enterText(find.byKey(WK.fieldAppointmentPayment), "10");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(PaymentPill), findsNWidgets(2));
          expect((find.byType(PaymentPill).evaluate().elementAt(0).widget as PaymentPill).title, "Price");
          expect((find.byType(PaymentPill).evaluate().elementAt(0).widget as PaymentPill).amount, "10.0");
          expect((find.byType(PaymentPill).evaluate().elementAt(1).widget as PaymentPill).title, "Paid");
          expect((find.byType(PaymentPill).evaluate().elementAt(1).widget as PaymentPill).amount, "10.0");

          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldAppointmentPrice), "5");
          await tester.enterText(find.byKey(WK.fieldAppointmentPayment), "10");
          await tester.pumpAndSettle();
          await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Save");
          await tester.pumpAndSettle();
          expect(find.byType(PaymentPill), findsNWidgets(3));
          expect((find.byType(PaymentPill).evaluate().elementAt(0).widget as PaymentPill).title, "Price");
          expect((find.byType(PaymentPill).evaluate().elementAt(0).widget as PaymentPill).amount, "5.0");
          expect((find.byType(PaymentPill).evaluate().elementAt(1).widget as PaymentPill).title, "Paid");
          expect((find.byType(PaymentPill).evaluate().elementAt(1).widget as PaymentPill).amount, "10.0");
          expect((find.byType(PaymentPill).evaluate().elementAt(2).widget as PaymentPill).title, "Overpaid");
          expect((find.byType(PaymentPill).evaluate().elementAt(2).widget as PaymentPill).amount, "5.0");
        },
        "19: Photos": () async {
          // TODO upload by link
        },
        "20: Close appointments": () async {
          while (true) {
            await tester.pumpAndSettle();
            final editIcons = find.byIcon(FluentIcons.edit);
            if (editIcons.evaluate().isEmpty) break;
            await tester.tap(editIcons.at(0));
            await tester.pumpAndSettle();
            await TestUtils.actionOnModal(tester, routes.openAppointment.id, "Archive");
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(const Key('closeModal')));
        }
      };
}
