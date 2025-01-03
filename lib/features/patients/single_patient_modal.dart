import 'package:apexo/app/routes.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/utils/color_based_on_payment.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/appointments/single_appointment_modal.dart';
import 'package:apexo/utils/print/print_link.dart';
import 'package:apexo/common_widgets/appointment_card.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/common_widgets/call_button.dart';
import 'package:apexo/common_widgets/dental_chart.dart';
import 'package:apexo/common_widgets/qrlink.dart';
import 'package:apexo/common_widgets/tag_input.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:apexo/features/patients/patient_model.dart';
import 'package:apexo/features/patients/patients_store.dart';
import 'package:apexo/features/settings/settings_stores.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart' hide TextBox;
import 'package:flutter/cupertino.dart';
import "../../common_widgets/tabbed_modal.dart";

openSinglePatient({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Patient) onSave,
  required bool editing,
  int selectedTab = 0,
  bool? showContinue,
}) {
  routes.openPatient = Patient.fromJson(json); // reset

  final o = routes.openPatient;
  showTabbedModal(
      key: Key(o.id),
      context: context,
      streams: [
        patients.observableObject.stream,
        appointments.observableObject.stream,
        doctors.observableObject.stream
      ],
      onArchive: o.archived != true && editing ? () => patients.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => patients.set(o..archived = null) : null,
      onSave: () {
        patients.set(routes.openPatient);
        onSave(routes.openPatient);
      },
      onContinue: (editing || showContinue != true)
          ? null
          : () {
              patients.set(routes.openPatient);
              openSinglePatient(
                context: context,
                json: routes.openPatient.toJson(),
                title: txt("editPatient"),
                onSave: onSave,
                editing: true,
                selectedTab: 2,
              );
            },
      initiallySelected: selectedTab,
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
                controller: TextEditingController(text: routes.openPatient.title),
                onChanged: (value) => routes.openPatient.title = value,
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
                    controller: TextEditingController(text: routes.openPatient.birth.toString()),
                    onChanged: (value) => routes.openPatient.birth = int.tryParse(value) ?? routes.openPatient.birth,
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
                        child: Txt("♂️ ${txt("male")}"),
                      ),
                      ComboBoxItem<int>(
                        value: 0,
                        child: Txt("♀️ ${txt("female")}"),
                      )
                    ],
                    value: routes.openPatient.gender,
                    onChanged: (value) {
                      routes.openPatient.gender = value ?? routes.openPatient.gender;
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
                    controller: TextEditingController(text: routes.openPatient.phone),
                    onChanged: (value) => routes.openPatient.phone = value,
                    prefix: CallIconButton(phoneNumber: routes.openPatient.phone),
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
                    controller: TextEditingController(text: routes.openPatient.email),
                    onChanged: (value) => routes.openPatient.email = value,
                  ),
                ),
              ),
            ]),
            InfoLabel(
              label: "${txt("address")}:",
              isHeader: true,
              child: CupertinoTextField(
                key: WK.fieldPatientAddress,
                controller: TextEditingController(text: routes.openPatient.address),
                onChanged: (value) => routes.openPatient.address = value,
                placeholder: "${txt("address")}...",
              ),
            ),
            InfoLabel(
              label: "${txt("notes")}:",
              isHeader: true,
              child: CupertinoTextField(
                key: WK.fieldPatientNotes,
                controller: TextEditingController(text: routes.openPatient.notes),
                onChanged: (value) => routes.openPatient.notes = value,
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
                  routes.openPatient.tags = List<String>.from(tags.map((e) => e.value).where((e) => e != null));
                },
                initialValue: routes.openPatient.tags.map((e) => TagInputItem(value: e, label: e)).toList(),
                strict: false,
                limit: 9999,
                placeholder: "${txt("patientTags")}...",
              ),
            )
          ],
        ),
        TabbedModal(
          title: txt("dentalNotes"),
          icon: FluentIcons.teeth,
          padding: 5,
          closable: true,
          content: (state) => [
            DentalChart(patient: routes.openPatient),
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
    content: (state) => routes.openPatient.allAppointments.isEmpty
        ? [
            InfoBar(title: Txt(txt("noAppointmentsFound"))),
          ]
        : [
            ...List.generate(routes.openPatient.allAppointments.length, (index) {
              final appointment = routes.openPatient.allAppointments[index];
              String? difference;
              if (routes.openPatient.allAppointments.last != appointment) {
                int differenceInDays =
                    appointment.date.difference(routes.openPatient.allAppointments[index + 1].date).inDays.abs();

                difference = "${txt("after")} $differenceInDays ${txt("day${(differenceInDays > 1) ? "s" : ""}")}";
              }
              return AppointmentCard(
                key: Key(appointment.id),
                appointment: appointment,
                difference: difference,
                hide: const [AppointmentSections.patient],
                number: index + 1,
              );
            }),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 50),
              child: Acrylic(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                elevation: 50,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: kElevationToShadow[4],
                      border: Border(
                          top: BorderSide(
                        color: colorBasedOnPayments(routes.openPatient.paymentsMade, routes.openPatient.pricesGiven)
                            .withValues(alpha: 0.3),
                        width: 5,
                      ))),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Txt("${txt("paymentSummary")} (${globalSettings.get("currency_______").value})",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 15),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          PaymentPill(
                            finalTextColor: Colors.grey,
                            title: txt("cost"),
                            amount: routes.openPatient.pricesGiven.toString(),
                            color: Colors.white,
                          ),
                          PaymentPill(
                            finalTextColor: Colors.grey,
                            title: txt("paid"),
                            amount: routes.openPatient.paymentsMade.toString(),
                            color: Colors.white,
                          ),
                          PaymentPill(
                            finalTextColor: Colors.grey,
                            title: routes.openPatient.overPaid
                                ? txt("overpaid")
                                : routes.openPatient.underPaid
                                    ? txt("underpaid")
                                    : txt("fullyPaid"),
                            amount: (routes.openPatient.paymentsMade - routes.openPatient.pricesGiven).abs().toString(),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
    actions: [
      TabAction(
        text: txt("addAppointment"),
        icon: FluentIcons.add_event,
        callback: (_) {
          openSingleAppointment(
            context: context,
            json: {"patientID": routes.openPatient.id},
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

TabbedModal webPageTab(BuildContext context) {
  return TabbedModal(
      title: txt("patientPage"),
      icon: FluentIcons.q_r_code,
      closable: true,
      spacing: 10,
      padding: 10,
      content: (state) => [
            InfoBar(
              title: Txt(txt("patientCanUseTheFollowing")),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: SelectableText(routes.openPatient.webPageLink),
            ),
            QRLink(link: routes.openPatient.webPageLink)
          ],
      actions: [
        TabAction(
            text: txt("printQR"),
            callback: (_) {
              printingQRCode(
                context,
                routes.openPatient.webPageLink,
                "Access your information",
                "Scan to visit link:\n${routes.openPatient.webPageLink}\nto access your appointments, payments and photos.",
              );
              return false;
            },
            icon: FluentIcons.print)
      ]);
}
