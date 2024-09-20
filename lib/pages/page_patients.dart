import 'package:apexo/backend/observable/model.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/page_calendar.dart';
import 'package:apexo/pages/widgets/acrylic_title.dart';
import 'package:apexo/pages/widgets/tag_input.dart';
import 'package:apexo/pages/widgets/week_calendar.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:fluent_ui/fluent_ui.dart' hide TextBox;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'widgets/archive_button.dart';
import "widgets/datatable.dart";
import "widgets/tabbed_modal.dart";

// ignore: must_be_immutable
class PatientPage extends ObservingWidget {
  PatientPage({super.key});

  @override
  getObservableState() {
    return [appointments.observableObject, patients.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: DataTable<Patient>(
        items: patients.showing,
        actions: [
          DataTableAction(
              callback: (_) async {
                openSinglePatient(
                  context: context,
                  json: {},
                  editing: false,
                  title: "Create new patient",
                  onSave: patients.add,
                );
              },
              icon: FluentIcons.add_friend,
              title: "Add new"),
          DataTableAction(
              callback: (ids) {
                for (var id in ids) {
                  patients.archive(id);
                }
              },
              icon: FluentIcons.archive,
              title: "Archive Selected")
        ],
        furtherActions: [
          const SizedBox(width: 5),
          Checkbox(
            style: const CheckboxThemeData(icon: FluentIcons.archive),
            checked: patients.showArchived,
            onChanged: patients.showArchivedChanged,
          )
        ],
        onSelect: (item) {
          openSinglePatient(
            context: context,
            json: item.toJson(),
            editing: true,
            title: "Edit patient",
            onSave: patients.modify,
          );
        },
      ),
    );
  }
}

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
      callback: () {
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
          SizedBox(width: 10),
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
                  patients.notify();
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
          SizedBox(width: 10),
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
    if (editing) appointmentsTab(context),
    if (editing) financesTab(context)
  ]);
}

TabbedModal appointmentsTab(BuildContext context) {
  return TabbedModal(
      title: "Appointments",
      icon: FluentIcons.calendar,
      closable: true,
      spacing: 0,
      padding: pages.openPatient.allAppointments.isEmpty ? 15 : 5,
      content: (state) => pages.openPatient.allAppointments.isEmpty
          ? const [InfoBar(title: Text("No appointments for this patient are found, use the button below to add one."))]
          : pages.openPatient.allAppointments
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
              json: {"patientID": pages.openPatient.id},
              title: "New appointment",
              onSave: appointments.add,
              editing: false,
            );
            return false;
          },
        ),
      ]);
}

// TODO: implment the checkbox (whether to account for entry or not)
TabbedModal financesTab(BuildContext context) {
  return TabbedModal(
    title: "Finances",
    icon: FluentIcons.money,
    closable: true,
    spacing: 5,
    padding: 5,
    heightFactor: pages.openPatient.doneAppointments.isEmpty ? 105 : 65,
    content: (state) => pages.openPatient.doneAppointments.isEmpty
        ? const [
            InfoBar(
                title: Text("No appointments for this patient have been done, hence no financial data is available."))
          ]
        : pages.openPatient.doneAppointments.map((appointment) => _buildFinanceLine(context, appointment)).toList(),
    footer: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text("${pages.openPatient.doneAppointments.length} appointments"),
      financesPaymentsNumbersToWidgets(pages.openPatient.paymentsMade, pages.openPatient.pricesGiven),
    ]),
  );
}

Container _buildFinanceLine(BuildContext context, Appointment appointment) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: colorBasedOnPayments(appointment.paid, appointment.price).withOpacity(0.1),
      ),
      color: Colors.white,
    ),
    child: ListTile(
      leading: Checkbox(checked: false, onChanged: (_) {}),
      onPressed: () => openSingleAppointment(
        context: context,
        json: appointment.toJson(),
        title: "Editing appointment",
        onSave: appointments.modify,
        editing: true,
      ),
      title: AcrylicTitle(
        radius: 5,
        item: Model.fromJson({"title": " ${DateFormat("dd/MM/yyyy").format(appointment.date())} "}),
        predefinedColor: colorBasedOnPayments(appointment.paid, appointment.price),
        maxWidth: 200,
      ),
      trailing: financesPaymentsNumbersToWidgets(appointment.paid, appointment.price),
    ),
  );
}

Widget financesPaymentsNumbersToWidgets(double paid, double price) {
  bool isOOverPaid = paid > price;
  bool isUnderpaid = paid < price;
  double difference = (price - paid).abs();

  return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text("$paid / $price",
        style: TextStyle(fontSize: 12, backgroundColor: colorBasedOnPayments(paid, price).withOpacity(0.1))),
    Text(
      "${isOOverPaid ? "Overpaid:" : isUnderpaid ? "Underpaid:" : "Paid:"}${difference == 0 ? " $paid" : " $difference"}",
      style: TextStyle(
          color: colorBasedOnPayments(paid, price), fontWeight: difference != 0 ? FontWeight.bold : null, fontSize: 12),
    ),
  ]);
}

Color colorBasedOnPayments(double paid, double price) {
  bool isOOverPaid = paid > price;
  bool isUnderpaid = paid < price;
  return isOOverPaid
      ? Colors.blue
      : isUnderpaid
          ? Colors.red
          : Colors.grey;
}
