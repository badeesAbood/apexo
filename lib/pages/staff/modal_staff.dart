import 'package:apexo/pages/calendar/modal_appointment.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/shared/appointment_card.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/shared/tag_input.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import '../shared/archive_button.dart';
import "../shared/tabbed_modal.dart";

openSingleMember({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Member) onSave,
  required bool editing,
}) {
  pages.openMember = Member.fromJson(json);
  List<TabAction> actions = [
    TabAction(
      text: "Save",
      icon: FluentIcons.save,
      callback: (_) {
        onSave(pages.openMember);
        return true;
      },
    )
  ];
  if (editing) actions.add(archiveButton(pages.openMember, staff));
  showTabbedModal(context: context, tabs: [
    TabbedModal(
      title: title,
      icon: FluentIcons.medical,
      closable: true,
      content: (state) => [
        InfoLabel(
          label: "Doctor name:",
          child: CupertinoTextField(
            controller: TextEditingController(text: pages.openMember.title),
            placeholder: "doctor name",
            onChanged: (val) {
              pages.openMember.title = val;
            },
          ),
        ),
        InfoLabel(
          label: "Doctor email:",
          child: CupertinoTextField(
            controller: TextEditingController(text: pages.openMember.email),
            placeholder: "email@server.com",
            onChanged: (val) {
              pages.openMember.email = val;
            },
          ),
        ),
        InfoLabel(
          label: "Duty days:",
          child: TagInputWidget(
            suggestions: [...allDays.map((e) => TagInputItem(value: e, label: e))],
            onChanged: (data) {
              pages.openMember.dutyDays = data.map((e) => e.value ?? "").where((e) => e.isNotEmpty).toList();
            },
            initialValue: [...pages.openMember.dutyDays.map((e) => TagInputItem(value: e, label: e))],
            strict: true,
            limit: 7,
          ),
        ),
      ],
      actions: actions,
    ),
    if (editing) upcomingAppointmentsTab(context),
  ]);
}

TabbedModal upcomingAppointmentsTab(BuildContext context) {
  return TabbedModal(
    title: "Appointments",
    icon: FluentIcons.calendar,
    closable: true,
    spacing: 0,
    padding: 0,
    headerToggle: (state) => ArchiveToggle(notifier: state.notify),
    content: (state) => pages.openMember.upcomingAppointments.isEmpty
        ? const [
            InfoBar(title: Text("No upcoming appointments found. Use the button below to register new one")),
          ]
        : [
            ...pages.openMember.upcomingAppointments.map((appointment) {
              String? difference;
              int index = pages.openMember.upcomingAppointments.indexOf(appointment);
              if (pages.openMember.upcomingAppointments.last != appointment) {
                int differenceInDays =
                    appointment.date().difference(pages.openMember.upcomingAppointments[index + 1].date()).inDays.abs();

                difference = "after $differenceInDays day${differenceInDays > 1 ? "s" : ""}";
              }
              return AppointmentCard(
                key: Key(appointment.id),
                appointment: appointment,
                difference: difference,
                hide: const [AppointmentSections.staff],
              );
            })
          ],
    actions: [
      TabAction(
        text: "New appointment",
        icon: FluentIcons.add_event,
        callback: (_) {
          openSingleAppointment(
            context: context,
            json: {
              "operatorsIDs": [pages.openMember.id]
            },
            title: "New appointment",
            onSave: appointments.set,
            editing: false,
          );
          return false;
        },
      ),
    ],
  );
}
