import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/calendar/modal_appointment.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/print/print_link.dart';
import 'package:apexo/pages/shared/appointment_card.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/shared/call_button.dart';
import 'package:apexo/pages/shared/qrlink.dart';
import 'package:apexo/pages/shared/tag_input.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart' hide TextBox;
import 'package:flutter/cupertino.dart';
import "../shared/tabbed_modal.dart";

openSinglePatient({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Patient) onSave,
  required bool editing,
}) {
  pages.openPatient = Patient.fromJson(json); // reset

  final o = pages.openPatient;
  showTabbedModal(
      key: Key(o.id),
      context: context,
      onArchive: o.archived != true && editing ? () => patients.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => patients.set(o..archived = null) : null,
      onSave: () => patients.set(pages.openPatient),
      tabs: [
        TabbedModal(
          title: title,
          icon: FluentIcons.medication_admin,
          closable: true,
          content: (state) => [
            InfoLabel(
              label: "${txt("name")}:",
              isHeader: true,
              child: CupertinoTextField(
                key: WK.fieldPatientName,
                placeholder: "${txt("name")}...",
                controller: TextEditingController(text: pages.openPatient.title),
                onChanged: (value) => pages.openPatient.title = value,
              ),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Expanded(
                child: InfoLabel(
                  label: "${txt("birthYear")}:",
                  isHeader: true,
                  child: CupertinoTextField(
                    key: WK.fieldPatientYOB,
                    placeholder: "${txt("birthYear")}...",
                    controller: TextEditingController(text: pages.openPatient.birth.toString()),
                    onChanged: (value) => pages.openPatient.birth = int.tryParse(value) ?? pages.openPatient.birth,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InfoLabel(
                  label: "${txt("gender")}:",
                  isHeader: true,
                  child: ComboBox<int>(
                    key: WK.fieldPatientGender,
                    isExpanded: true,
                    items: [
                      ComboBoxItem<int>(
                        value: 1,
                        child: Text("♂️ ${txt("male")}"),
                      ),
                      ComboBoxItem<int>(
                        value: 0,
                        child: Text("♀️ ${txt("female")}"),
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
                  label: "${txt("phone")}:",
                  isHeader: true,
                  child: CupertinoTextField(
                    key: WK.fieldPatientPhone,
                    placeholder: "${txt("phone")}...",
                    controller: TextEditingController(text: pages.openPatient.phone),
                    onChanged: (value) => pages.openPatient.phone = value,
                    prefix: CallIconButton(phoneNumber: pages.openPatient.phone),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InfoLabel(
                  label: "${txt("email")}:",
                  isHeader: true,
                  child: CupertinoTextField(
                    key: WK.fieldPatientEmail,
                    placeholder: "${txt("email")}...",
                    controller: TextEditingController(text: pages.openPatient.email),
                    onChanged: (value) => pages.openPatient.email = value,
                  ),
                ),
              ),
            ]),
            InfoLabel(
              label: "${txt("address")}:",
              isHeader: true,
              child: CupertinoTextField(
                key: WK.fieldPatientAddress,
                controller: TextEditingController(text: pages.openPatient.address),
                onChanged: (value) => pages.openPatient.address = value,
                placeholder: "${txt("address")}...",
              ),
            ),
            InfoLabel(
              label: "${txt("notes")}:",
              isHeader: true,
              child: CupertinoTextField(
                key: WK.fieldPatientNotes,
                controller: TextEditingController(text: pages.openPatient.notes),
                onChanged: (value) => pages.openPatient.notes = value,
                maxLines: null,
                placeholder: "${txt("notes")}...",
              ),
            ),
            InfoLabel(
              label: "${txt("patientTags")}:",
              isHeader: true,
              child: TagInputWidget(
                key: WK.fieldPatientTags,
                suggestions: patients.allTags.map((t) => TagInputItem(value: t, label: t)).toList(),
                onChanged: (tags) {
                  pages.openPatient.tags = List<String>.from(tags.map((e) => e.value).where((e) => e != null));
                },
                initialValue: pages.openPatient.tags.map((e) => TagInputItem(value: e, label: e)).toList(),
                strict: false,
                limit: 9999,
                placeholder: "${txt("patientTags")}...",
              ),
            )
          ],
        ),
        if (editing) ...[appointmentsTab(context), webPageTab(context)]
      ]);
}

TabbedModal appointmentsTab(BuildContext context) {
  return TabbedModal(
    title: txt("appointments"),
    icon: FluentIcons.calendar,
    closable: true,
    spacing: 0,
    padding: 0,
    headerToggle: (state) => ArchiveToggle(notifier: state.notify),
    content: (state) => pages.openPatient.allAppointments.isEmpty
        ? [
            InfoBar(title: Text(txt("noAppointmentsFound"))),
          ]
        : [
            ...pages.openPatient.allAppointments.map((appointment) {
              String? difference;
              int index = pages.openPatient.allAppointments.indexOf(appointment);
              if (pages.openPatient.allAppointments.last != appointment) {
                int differenceInDays =
                    appointment.date().difference(pages.openPatient.allAppointments[index + 1].date()).inDays.abs();

                difference = "${txt("after")} $differenceInDays ${txt("day${(differenceInDays > 1) ? "s" : ""}")}";
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
        text: txt("newAppointment"),
        icon: FluentIcons.add_event,
        callback: (_) {
          openSingleAppointment(
            context: context,
            json: {"patientID": pages.openPatient.id},
            title: txt("newAppointment"),
            onSave: appointments.set,
            editing: false,
          );
          return false;
        },
      ),
    ],
  );
}

TabbedModal webPageTab(BuildContext context) {
  return TabbedModal(
      title: txt("patientPage"),
      icon: FluentIcons.q_r_code,
      closable: true,
      spacing: 10,
      padding: 10,
      content: (state) => [
            InfoBar(
              title: Text(txt("patientCanUseTheFollowing")),
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: SelectableText(pages.openPatient.webPageLink),
            ),
            QRLink(link: pages.openPatient.webPageLink)
          ],
      actions: [
        TabAction(
            text: txt("printQR"),
            callback: (_) {
              printingQRCode(
                context,
                pages.openPatient.webPageLink,
                "Access your information",
                "Scan to visit link:\n${pages.openPatient.webPageLink}\nto access your appointments, payments and photos.",
              );
              return false;
            },
            icon: FluentIcons.print)
      ]);
}
