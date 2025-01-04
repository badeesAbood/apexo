import 'package:apexo/app/routes.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/appointments/single_appointment_modal.dart';
import 'package:apexo/common_widgets/appointment_card.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/common_widgets/tag_input.dart';
import 'package:apexo/services/login.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/features/doctors/doctor_model.dart';
import 'package:apexo/services/network.dart';
import 'package:apexo/services/users.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import "../../common_widgets/tabbed_modal.dart";

openSingleDoctor({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Doctor) onSave,
  required bool editing,
  int selectedTab = 0,
  bool? showContinue,
}) {
  routes.openMember = Doctor.fromJson(json);
  final o = routes.openMember;
  showTabbedModal(
      key: Key(o.id),
      streams: [appointments.observableMap.stream, doctors.observableMap.stream],
      context: context,
      onArchive: o.archived != true && editing ? () => doctors.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => doctors.set(o..archived = null) : null,
      onSave: () => doctors.set(routes.openMember),
      onContinue: (editing || showContinue != true)
          ? null
          : () {
              doctors.set(routes.openMember);
              openSingleDoctor(
                context: context,
                json: routes.openMember.toJson(),
                title: "${txt("edit")} ${txt("doctor")}",
                onSave: onSave,
                editing: true,
                selectedTab: 1,
              );
            },
      initiallySelected: selectedTab,
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
                controller: TextEditingController(text: routes.openMember.title),
                placeholder: "${txt("doctorName")}...",
                onChanged: (val) {
                  routes.openMember.title = val;
                },
              ),
            ),
            InfoLabel(
              label: "${txt("doctorEmail")}:",
              child: CupertinoTextField(
                key: WK.fieldDoctorEmail,
                controller: TextEditingController(text: routes.openMember.email),
                placeholder: "${txt("doctorEmail")}...",
                onChanged: (val) {
                  routes.openMember.email = val;
                },
              ),
            ),
            InfoLabel(
              label: "${txt("dutyDays")}:",
              child: TagInputWidget(
                key: WK.fieldDutyDays,
                suggestions: [...allDays.map((e) => TagInputItem(value: e, label: txt(e)))],
                onChanged: (data) {
                  routes.openMember.dutyDays = data.map((e) => e.value ?? "").where((e) => e.isNotEmpty).toList();
                },
                initialValue: [...routes.openMember.dutyDays.map((e) => TagInputItem(value: e, label: txt(e)))],
                strict: true,
                limit: 7,
              ),
            ),
            if (login.isAdmin && network.isOnline())
              InfoLabel(
                label: "${txt("lockToUsers")}:",
                child: TagInputWidget(
                  suggestions: [...users.list().map((e) => TagInputItem(value: e.id, label: e.data["email"]))],
                  onChanged: (data) {
                    routes.openMember.lockToUserIDs =
                        data.map((e) => e.value ?? "").where((e) => e.isNotEmpty).toList();
                  },
                  initialValue: [
                    ...routes.openMember.lockToUserIDs.map((e) => TagInputItem(
                        value: e,
                        label: users.list().where((u) => u.id == e).firstOrNull?.data["email"] ?? "NOT FOUND: $e")),
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

upcomingAppointmentsTab(BuildContext context) {
  return TabbedModal(
    title: txt("appointments"),
    icon: FluentIcons.calendar,
    closable: true,
    spacing: 0,
    padding: 0,
    headerToggle: (state) => ArchiveToggle(notifier: state.rebuildSheet),
    content: (state) => routes.openMember.upcomingAppointments.isEmpty
        ? const [
            InfoBar(title: Txt("No upcoming appointments found. Use the button below to register new one")),
          ]
        : [
            ...List.generate(routes.openMember.upcomingAppointments.length, (index) {
              final appointment = routes.openMember.upcomingAppointments[index];
              String? difference;
              if (routes.openMember.upcomingAppointments.last != appointment) {
                int differenceInDays =
                    appointment.date.difference(routes.openMember.upcomingAppointments[index + 1].date).inDays.abs();

                difference = "after $differenceInDays day${differenceInDays > 1 ? "s" : ""}";
              }
              return AppointmentCard(
                key: Key(appointment.id),
                appointment: appointment,
                difference: difference,
                hide: const [AppointmentSections.doctors],
                number: index + 1,
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
              "operatorsIDs": [routes.openMember.id]
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
