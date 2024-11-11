import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/page_calendar.dart';
import 'package:apexo/pages/widgets/appointment_card.dart';
import 'package:apexo/pages/widgets/archive_toggle.dart';
import 'package:apexo/pages/widgets/tag_input.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/archive_button.dart';
import "widgets/datatable.dart";
import "widgets/tabbed_modal.dart";

class StaffMembers extends ObservingWidget {
  const StaffMembers({super.key});

  @override
  getObservableState() {
    return [staff.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: DataTable<Member>(
        items: staff.showing,
        actions: [
          DataTableAction(
            callback: (_) => openSingleMember(
              context: context,
              json: {},
              title: "Add new",
              onSave: staff.add,
              editing: false,
            ),
            icon: FluentIcons.medical,
            title: "Add new",
          ),
          DataTableAction(
            callback: (ids) {
              for (var id in ids) {
                staff.archive(id);
              }
            },
            icon: FluentIcons.archive,
            title: "Archive Selected",
          )
        ],
        furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: staff.notify)],
        onSelect: (item) => openSingleMember(
          context: context,
          json: item.toJson(),
          title: "Edit staff member",
          onSave: staff.modify,
          editing: true,
        ),
      ),
    );
  }
}

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
            onSave: appointments.add,
            editing: false,
          );
          return false;
        },
      ),
    ],
  );
}
