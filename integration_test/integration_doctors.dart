import 'package:apexo/pages/index.dart';
import 'package:apexo/common_widgets/item_title.dart';
import 'package:apexo/common_widgets/appointment_card.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

class DoctorsPageIntegrationTest extends IntegrationTestBase {
  DoctorsPageIntegrationTest({required super.tester});

  @override
  String get name => 'doctors';

  @override
  Map<String, Future<Null> Function()> get tests => {
        "01: Should move to doctors page++": () async {
          await tester.tap(find.byKey(const Key('doctors_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.doctorsScreen), findsOneWidget);
        },
        "02: should add doctors++": () async {
          await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldDoctorName), "Ali A. Saleem");
          await tester.enterText(find.byKey(WK.fieldDoctorEmail), "alielselawi@gmail.com");
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldDoctorName), "Dina Ismail");
          await tester.enterText(find.byKey(WK.fieldDoctorEmail), "dinaibak92@gmail.com");
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
          await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldDoctorName), "Alia A. Saleem");
          await tester.enterText(find.byKey(WK.fieldDoctorEmail), "aliasaleem@gmail.com");
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
        },
        "03: Archive selected": () async {
          final id1 = doctors.getByEmail("alielselawi@gmail.com")!.id;
          final id2 = doctors.getByEmail("aliasaleem@gmail.com")!.id;
          await tester.tap(find.byKey(Key('dt_cb_$id1')));
          await tester.tap(find.byKey(Key('dt_cb_$id2')));
          await tester.tap(find.widgetWithText(GestureDetector, 'Archive Selected'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsNothing);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsNothing);
          await Future.delayed(const Duration(seconds: 1));
        },
        "04: Archive toggle": () async {
          await tester.tap(find.byType(ArchiveToggle));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
          await Future.delayed(const Duration(seconds: 1));
          await tester.tap(find.byType(ArchiveToggle));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsNothing);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsNothing);
          await Future.delayed(const Duration(seconds: 1));
          await tester.tap(find.byType(ArchiveToggle));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
        },
        "05: Restore button": () async {
          await tester.tap(find.widgetWithText(ItemTitle, 'Alia A. Saleem'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, "Restore"));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ItemTitle, 'Ali A. Saleem'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, "Restore"));
          await tester.pumpAndSettle();
        },
        "06: Archive button": () async {
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, "Archive"));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
          await Future.delayed(const Duration(seconds: 1));
          await tester.tap(find.byType(ArchiveToggle));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsNothing);
          await Future.delayed(const Duration(seconds: 1));
          await tester.tap(find.byType(ArchiveToggle));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, "Restore"));
          await tester.pumpAndSettle();
          await Future.delayed(const Duration(seconds: 1));
          await tester.tap(find.byType(ArchiveToggle));
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
        },
        '07: "Showing" shows correct number': () async {
          expect(find.text('Showing 3/3'), findsOneWidget);
        },
        "08: Search": () async {
          await tester.enterText(find.byKey(WK.dataTableSearch), "Saleem");
          await tester.pumpAndSettle();
          expect(find.text('Showing 2/2'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsNothing);
          await tester.enterText(find.byKey(WK.dataTableSearch), "Dina");
          await tester.pumpAndSettle();
          expect(find.text('Showing 1/1'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsNothing);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsNothing);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
          await tester.enterText(find.byKey(WK.dataTableSearch), "");
          await tester.pumpAndSettle();
          expect(find.text('Showing 3/3'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Ali A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Alia A. Saleem'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
        },
        "09: Sorting direction": () async {
          {
            final textFinder = find.byType(ItemTitle);
            final texts = tester.widgetList<ItemTitle>(textFinder).toList();
            final names = texts.map((e) => e.item.title).toList();
            expect(names, ["Ali A. Saleem", "Alia A. Saleem", "Dina Ismail"]);
          }
          await tester.tap(find.byKey(WK.toggleSortDirection));
          await tester.pumpAndSettle();
          {
            final textFinder = find.byType(ItemTitle);
            final texts = tester.widgetList<ItemTitle>(textFinder).toList();
            final names = texts.map((e) => e.item.title).toList();
            expect(names, ["Dina Ismail", "Alia A. Saleem", "Ali A. Saleem"]);
          }
        },
        "10: Editing but closing": () async {
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldDoctorName), "Dina Ismael");
          await tester.tap(find.byKey(WK.closeModal));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismael'), findsNothing);
        },
        "11: Editing but canceling": () async {
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldDoctorName), "Dina Ismael");
          await tester.tap(find.widgetWithText(FilledButton, "Cancel"));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismael'), findsNothing);
        },
        "12: Editing and saving": () async {
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldDoctorName), "Dina Ismael");
          await tester.tap(find.widgetWithText(FilledButton, "Save"));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsNothing);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismael'), findsOneWidget);

          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismael'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldDoctorName), "Dina Ismail");
          await tester.tap(find.widgetWithText(FilledButton, "Save"));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ItemTitle, 'Dina Ismail'), findsOneWidget);
          expect(find.widgetWithText(ItemTitle, 'Dina Ismael'), findsNothing);
        },
        "13: Editing duty days": () async {
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          await tester
              .tap(find.descendant(of: find.widgetWithText(IconButton, "Saturday"), matching: find.byType(IconButton)));
          await tester
              .tap(find.descendant(of: find.widgetWithText(IconButton, "Sunday"), matching: find.byType(IconButton)));
          await tester.tap(
              find.descendant(of: find.widgetWithText(IconButton, "Wednesday"), matching: find.byType(IconButton)));
          await tester
              .tap(find.descendant(of: find.widgetWithText(IconButton, "Thursday"), matching: find.byType(IconButton)));
          await tester
              .tap(find.descendant(of: find.widgetWithText(IconButton, "Friday"), matching: find.byType(IconButton)));
          await tester
              .tap(find.descendant(of: find.widgetWithText(IconButton, "Monday"), matching: find.byType(IconButton)));
          await tester.tap(find.widgetWithText(FilledButton, "Save"));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(IconButton, "Saturday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Sunday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Wednesday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Thursday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Friday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Monday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Tuesday"), findsOneWidget);
          await tester.enterText(find.byKey(WK.fieldDutyDays), "mon");
          await tester.pumpAndSettle();
          await tester.tap(find.text('Monday'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, "Save"));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ItemTitle, 'Dina Ismail'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(IconButton, "Saturday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Sunday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Wednesday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Thursday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Friday"), findsNothing);
          expect(find.widgetWithText(IconButton, "Monday"), findsOneWidget);
          expect(find.widgetWithText(IconButton, "Tuesday"), findsOneWidget);
        },
        "14: Moving back and forth between tabs": () async {
          await tester.tap(find.byKey(WK.tabbedModalNext));
          await tester.pumpAndSettle();
          expect(find.text('Add Appointment'), findsOneWidget);
          expect(find.byKey(WK.fieldDutyDays), findsNothing);

          await tester.tap(find.byKey(WK.tabbedModalBack));
          await tester.pumpAndSettle();
          expect(find.text('Add Appointment'), findsNothing);
          expect(find.byKey(WK.fieldDutyDays), findsOneWidget);
        },
        "15: Navigating in tabs using top icons": () async {
          await tester.tap(find.byKey(const Key("Appointments_icon")));
          await tester.pumpAndSettle();
          expect(find.text('Add Appointment'), findsOneWidget);
          expect(find.byKey(WK.fieldDutyDays), findsNothing);

          await tester.tap(find.byKey(const Key("Edit Doctor_icon")));
          await tester.pumpAndSettle();
          expect(find.text('Add Appointment'), findsNothing);
          expect(find.byKey(WK.fieldDutyDays), findsOneWidget);
        },
        "16: Creating upcoming appointments": () async {
          await tester.tap(find.byKey(const Key("Appointments_icon")));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add Appointment'));
          await tester.pumpAndSettle();
          await tester.tap(find.descendant(
              of: find.byKey(Key(pages.openAppointment.id)), matching: find.widgetWithText(FilledButton, "Save")));
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsNothing); // not upcoming

          await tester.tap(find.byKey(const Key("Appointments_icon")));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add Appointment'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Change Date'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(GestureDetector, (DateTime.now().day + 1).toString()));
          // ^ this would fail on the last day of month
          // but I can live with that
          await tester.tap(find.widgetWithText(GestureDetector, 'OK'));
          await tester.pumpAndSettle();
          await tester.tap(find.descendant(
              of: find.byKey(Key(pages.openAppointment.id)), matching: find.widgetWithText(FilledButton, "Save")));
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
        },
        "17: Archive toggle inside upcoming appointments": () async {
          await tester.tap(find.byIcon(FluentIcons.edit));
          await tester.pumpAndSettle();
          await tester.tap(find.descendant(
              of: find.byKey(Key(pages.openAppointment.id)), matching: find.widgetWithText(FilledButton, "Archive")));
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsNothing);
          await tester
              .tap(find.descendant(of: find.byKey(Key(pages.openMember.id)), matching: find.byType(ArchiveToggle)));
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsOneWidget);
          expect(find.descendant(of: find.byType(AppointmentCard), matching: find.byIcon(FluentIcons.archive)),
              findsOneWidget);
          await tester
              .tap(find.descendant(of: find.byKey(Key(pages.openMember.id)), matching: find.byType(ArchiveToggle)));
          await tester.pumpAndSettle();
          expect(find.byType(AppointmentCard), findsNothing);
          await tester.tap(find.text("Save"));
          await tester.pumpAndSettle();
        }

        //TODO: "18: Locking to specific user": () async {},
      };
}
