import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/page_calendar.dart';
import 'package:apexo/pages/widgets/tag_input.dart';
import 'package:apexo/pages/widgets/week_calendar.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/archive_button.dart';
import "widgets/datatable.dart";
import "widgets/tabbed_modal.dart";

// ignore: must_be_immutable
class StaffMembers extends ObservingWidget {
  StaffMembers({super.key});

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
        furtherActions: [
          const SizedBox(width: 5),
          Checkbox(
            style: const CheckboxThemeData(icon: FluentIcons.archive),
            checked: staff.showArchived,
            onChanged: staff.showArchivedChanged,
          )
        ],
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
      callback: () {
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
          label: "Staff name:",
          child: CupertinoTextField(
            controller: TextEditingController(text: pages.openMember.title),
            placeholder: "Staff name",
            onChanged: (val) {
              pages.openMember.title = val;
            },
          ),
        ),
        Checkbox(
          checked: pages.openMember.operates,
          onChanged: (checked) {
            pages.openMember.operates = checked ?? false;
            state.notify();
          },
          content: Text("Operates on patients"),
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
        InfoLabel(
          label: "Can view the following pages:",
          child: TagInputWidget(
            suggestions: [...pages.allPages.map((p) => TagInputItem(value: p.identifier, label: p.title))],
            onChanged: (data) {
              pages.openMember.canView = data.map((v) => v.value ?? "").where((e) => e.isNotEmpty).toList();
            },
            initialValue: [
              ...pages.openMember.canView.map((v) =>
                  TagInputItem(value: v, label: pages.getByIdentifier(v) != null ? pages.getByIdentifier(v)!.title : v))
            ],
            strict: true,
            limit: 999,
          ),
        ),
        InfoLabel(
          label: "Can edit the following pages:",
          child: TagInputWidget(
            suggestions: [...pages.allPages.map((p) => TagInputItem(value: p.identifier, label: p.title))],
            onChanged: (data) {
              pages.openMember.canEdit = data.map((v) => v.value ?? "").where((e) => e.isNotEmpty).toList();
            },
            initialValue: [
              ...pages.openMember.canEdit.map((v) =>
                  TagInputItem(value: v, label: pages.getByIdentifier(v) != null ? pages.getByIdentifier(v)!.title : v))
            ],
            strict: true,
            limit: 999,
          ),
        ),
      ],
      actions: actions,
    ),
    if (editing && pages.openMember.operates) upcomingAppointmentsTab(context),
  ]);
}

TabbedModal upcomingAppointmentsTab(BuildContext context) {
  return TabbedModal(
      title: "Upcoming appointments",
      icon: FluentIcons.forward_event,
      closable: true,
      spacing: 0,
      padding: pages.openMember.upcomingAppointments.isEmpty ? 15 : 5,
      content: (state) => pages.openMember.upcomingAppointments.isEmpty
          ? const [InfoBar(title: Text("No upcoming appointments for this staff member are found."))]
          : pages.openMember.upcomingAppointments
              .map((e) => AppointmentTile(
                    item: e,
                    onSetTime: (item) {},
                    onSelect: (item) {
                      openSingleAppointment(
                        context: context,
                        json: item.toJson(),
                        title: "Editing appointment",
                        onSave: appointments.modify,
                        editing: true,
                      );
                    },
                    showLeadingIcon: false,
                    showFullDate: true,
                    showSubtitleLine2: false,
                    inModal: true,
                  ))
              .toList(),
      actions: [
        TabAction(
          text: "New appointment",
          icon: FluentIcons.add_event,
          callback: () {
            openSingleAppointment(
              context: context,
              json: {
                "operatorsIDs": [pages.openMember.id],
                "date": DateTime.now().add(Duration(days: 1)).millisecondsSinceEpoch,
              },
              title: "New appointment",
              onSave: appointments.add,
              editing: false,
            );
            return false;
          },
        ),
      ]);
}
