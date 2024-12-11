import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/calendar/modal_appointment.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/shared/appointment_card.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/shared/tag_input.dart';
import 'package:apexo/state/state.dart' as appState;
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/users.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import "../shared/tabbed_modal.dart";

openSingleMember({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Member) onSave,
  required bool editing,
}) {
  pages.openMember = Member.fromJson(json);
  final o = pages.openMember;
  showTabbedModal(
      context: context,
      onArchive: o.archived != true && editing ? () => staff.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => staff.set(o..archived = null) : null,
      onSave: () => staff.set(pages.openMember),
      key: Key(o.id),
      tabs: [
        TabbedModal(
          title: title,
          icon: FluentIcons.medical,
          closable: true,
          content: (state) => [
            InfoLabel(
              label: "${txt("doctorName")}:",
              child: CupertinoTextField(
                key: WK.fieldDoctorName,
                controller: TextEditingController(text: pages.openMember.title),
                placeholder: "${txt("doctorName")}...",
                onChanged: (val) {
                  pages.openMember.title = val;
                },
              ),
            ),
            InfoLabel(
              label: "${txt("doctorEmail")}:",
              child: CupertinoTextField(
                key: WK.fieldDoctorEmail,
                controller: TextEditingController(text: pages.openMember.email),
                placeholder: "${txt("doctorEmail")}...",
                onChanged: (val) {
                  pages.openMember.email = val;
                },
              ),
            ),
            InfoLabel(
              label: "${txt("dutyDays")}:",
              child: TagInputWidget(
                key: WK.fieldDutyDays,
                suggestions: [...allDays.map((e) => TagInputItem(value: e, label: txt(e)))],
                onChanged: (data) {
                  pages.openMember.dutyDays = data.map((e) => e.value ?? "").where((e) => e.isNotEmpty).toList();
                },
                initialValue: [...pages.openMember.dutyDays.map((e) => TagInputItem(value: e, label: txt(e)))],
                strict: true,
                limit: 7,
              ),
            ),
            if (appState.state.isAdmin)
              InfoLabel(
                label: "${txt("lockToUsers")}:",
                child: TagInputWidget(
                  suggestions: [...users.list.map((e) => TagInputItem(value: e.id, label: e.data["email"]))],
                  onChanged: (data) {
                    pages.openMember.lockToUserIDs = data.map((e) => e.value ?? "").where((e) => e.isNotEmpty).toList();
                  },
                  initialValue: [
                    ...pages.openMember.lockToUserIDs.map((e) => TagInputItem(
                        value: e,
                        label: users.list.where((u) => u.id == e).firstOrNull?.data["email"] ?? "NOT FOUND: $e")),
                  ],
                  strict: true,
                  limit: 9999,
                ),
              ),
          ],
        ),
        if (editing) upcomingAppointmentsTab(context),
      ]);
}

TabbedModal upcomingAppointmentsTab(BuildContext context) {
  return TabbedModal(
    title: txt("appointments"),
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
        text: txt("addAppointment"),
        icon: FluentIcons.add_event,
        callback: (_) {
          openSingleAppointment(
            context: context,
            json: {
              "operatorsIDs": [pages.openMember.id]
            },
            title: txt("addAppointment"),
            onSave: appointments.set,
            editing: false,
          );
          return false;
        },
      ),
    ],
  );
}
