import 'package:apexo/pages/calendar/modal_appointment.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/shared/appointment_card.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/shared/tag_input.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:fluent_ui/fluent_ui.dart' hide TextBox;
import 'package:flutter/cupertino.dart';
import '../shared/archive_button.dart';
import "../shared/tabbed_modal.dart";

openSinglePatient({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Patient) onSave,
  required bool editing,
}) {
  pages.openPatient = Patient.fromJson(json); // reset
  List<TabAction> actions = [
    TabAction(
      text: "Save",
      icon: FluentIcons.save,
      callback: (_) {
        onSave(pages.openPatient);
        return true;
      },
    )
  ];
  if (editing) actions.add(archiveButton(pages.openPatient, patients));

  showTabbedModal(context: context, tabs: [
    TabbedModal(
      title: title,
      icon: FluentIcons.medication_admin,
      closable: true,
      content: (state) => [
        InfoLabel(
          label: "Name:",
          isHeader: true,
          child: CupertinoTextField(
            placeholder: "name",
            controller: TextEditingController(text: pages.openPatient.title),
            onChanged: (value) => pages.openPatient.title = value,
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Expanded(
            child: InfoLabel(
              label: "Birth year:",
              isHeader: true,
              child: CupertinoTextField(
                placeholder: "birth year",
                controller: TextEditingController(text: pages.openPatient.birth.toString()),
                onChanged: (value) => pages.openPatient.birth = int.tryParse(value) ?? pages.openPatient.birth,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InfoLabel(
              label: "Gender:",
              isHeader: true,
              child: ComboBox<int>(
                isExpanded: true,
                items: const [
                  ComboBoxItem<int>(
                    value: 1,
                    child: Text("Male"),
                  ),
                  ComboBoxItem<int>(
                    value: 0,
                    child: Text("Female"),
                  )
                ],
                value: pages.openPatient.gender,
                onChanged: (value) {
                  pages.openPatient.gender = value ?? pages.openPatient.gender;
                  state.notify();
                },
              ),
            ),
          ),
        ]),
        Row(children: [
          Expanded(
            child: InfoLabel(
              label: "Phone number:",
              isHeader: true,
              child: CupertinoTextField(
                placeholder: "Phone number",
                controller: TextEditingController(text: pages.openPatient.phone),
                onChanged: (value) => pages.openPatient.phone = value,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InfoLabel(
              label: "Email:",
              isHeader: true,
              child: CupertinoTextField(
                placeholder: "Email",
                controller: TextEditingController(text: pages.openPatient.email),
                onChanged: (value) => pages.openPatient.email = value,
              ),
            ),
          ),
        ]),
        InfoLabel(
          label: "Address:",
          isHeader: true,
          child: CupertinoTextField(
            controller: TextEditingController(text: pages.openPatient.address),
            onChanged: (value) => pages.openPatient.address = value,
            placeholder: "Address",
          ),
        ),
        InfoLabel(
          label: "Notes:",
          isHeader: true,
          child: CupertinoTextField(
            controller: TextEditingController(text: pages.openPatient.notes),
            onChanged: (value) => pages.openPatient.notes = value,
            maxLines: null,
            placeholder: "Notes",
          ),
        ),
        InfoLabel(
          label: "Patient tags:",
          isHeader: true,
          child: TagInputWidget(
            suggestions: patients.allTags.map((t) => TagInputItem(value: t, label: t)).toList(),
            onChanged: (tags) {
              pages.openPatient.tags = List<String>.from(tags.map((e) => e.value).where((e) => e != null));
            },
            initialValue: pages.openPatient.tags.map((e) => TagInputItem(value: e, label: e)).toList(),
            strict: false,
            limit: 9999,
            placeholder: "Patient tags",
          ),
        )
      ],
      actions: actions,
    ),
    if (editing) appointmentsTab(context)
  ]);
}

TabbedModal appointmentsTab(BuildContext context) {
  return TabbedModal(
    title: "Appointments",
    icon: FluentIcons.calendar,
    closable: true,
    spacing: 0,
    padding: 0,
    headerToggle: (state) => ArchiveToggle(notifier: state.notify),
    content: (state) => pages.openPatient.allAppointments.isEmpty
        ? const [
            InfoBar(
                title: Text("No appointments found for this patient, use the button below to add new appointment.")),
          ]
        : [
            ...pages.openPatient.allAppointments.map((appointment) {
              String? difference;
              int index = pages.openPatient.allAppointments.indexOf(appointment);
              if (pages.openPatient.allAppointments.last != appointment) {
                int differenceInDays =
                    appointment.date().difference(pages.openPatient.allAppointments[index + 1].date()).inDays.abs();

                difference = "after $differenceInDays day${differenceInDays > 1 ? "s" : ""}";
              }
              return AppointmentCard(
                key: Key(appointment.id),
                appointment: appointment,
                difference: difference,
                hide: const [AppointmentSections.patient],
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
            json: {"patientID": pages.openPatient.id},
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
