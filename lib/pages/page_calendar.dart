import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/page_patients.dart';
import 'package:apexo/pages/page_staff.dart';
import 'package:apexo/pages/widgets/acrylic_button.dart';
import 'package:apexo/pages/widgets/date_time_picker.dart';
import 'package:apexo/pages/widgets/tag_input.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import './widgets/tabbed_modal.dart';
import './widgets/archive_button.dart';
import './widgets/week_calendar.dart';
import '../../state/stores/appointments/appointment_model.dart';
import '../../state/stores/appointments/appointments_store.dart';

// ignore: must_be_immutable
class Calendar extends ObservingWidget {
  Calendar({super.key});

  @override
  getObservableState() {
    return [appointments.observableObject, patients.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: WeekAgendaCalendar<Appointment>(
        items: appointments.filtered,
        actions: [
          ComboBox<String>(
            style: const TextStyle(overflow: TextOverflow.ellipsis),
            items: [
              const ComboBoxItem<String>(
                value: "",
                child: Text("All operators"),
              ),
              ...staff.present.map((e) {
                var doctorName = e.title;
                if (doctorName.length > 20) {
                  doctorName = doctorName.substring(0, 17) + "...";
                }
                return ComboBoxItem(value: e.id, child: Text(doctorName));
              }),
            ],
            onChanged: appointments.filterByStaff,
            value: appointments.staffId,
          ),
          const SizedBox(width: 5),
          Checkbox(
            checked: appointments.showArchived,
            onChanged: appointments.showArchivedChanged,
            style: const CheckboxThemeData(icon: FluentIcons.archive),
          )
        ],
        startDay: "saturday",
        initiallySelectedDay: DateTime.now().millisecondsSinceEpoch,
        onSetTime: (item) {
          appointments.modify(item);
        },
        onSelect: (item) {
          openSingleAppointment(
            context: context,
            title: "Appointment",
            json: item.toJson(),
            onSave: appointments.modify,
            editing: true,
          );
        },
        onAddNew: (selectedDate) {
          openSingleAppointment(
            context: context,
            title: "Add new",
            json: {"date": selectedDate.millisecondsSinceEpoch},
            onSave: appointments.add,
            editing: false,
          );
        },
      ),
    );
  }
}

// TODO: bug: go to 16 / september 2024
// try to check/uncheck the checkbox as fast as you can
// inconsistent result will appear due to multiple calls to synchronize
// would an increased bouncing solve it?
// would a check against local DB _ts_ solve it?
// why is it happening?

openSingleAppointment({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Appointment) onSave,
  required bool editing,
}) {
  pages.openAppointment = Appointment.fromJson(json); // reset
  List<TabAction> actions = [
    TabAction(
      text: "Save",
      icon: FluentIcons.save,
      callback: () {
        onSave(pages.openAppointment);
        return true;
      },
    )
  ];
  if (editing) actions.add(archiveButton(pages.openAppointment, appointments));

  showTabbedModal(context: context, tabs: [
    TabbedModal(
      title: title,
      icon: FluentIcons.add_event,
      closable: true,
      actions: actions,
      heightFactor: 110,
      content: (state) => [
        InfoLabel(
          label: "Patient:",
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: TagInputWidget(
                /// rebuild needed if a new patient added
                /// while creating/editing the appointment
                key: Key(pages.openAppointment.patientID ?? ""),
                onItemTap: (tag) {
                  Patient? tapped = patients.get(tag.value ?? "");
                  Map<String, dynamic> json = tapped != null ? tapped.toJson() : {};
                  openSinglePatient(
                      context: context, json: json, title: "Patient Details", onSave: patients.modify, editing: true);
                },
                suggestions: patients.present.map((e) => TagInputItem(value: e.id, label: e.title)).toList(),
                onChanged: (s) {
                  if (s.isNotEmpty) {
                    pages.openAppointment.patientID = s.first.value;
                  } else {
                    pages.openAppointment.patientID = null;
                  }
                  state.notify();
                },
                initialValue: pages.openAppointment.patientID != null
                    ? [
                        TagInputItem(
                            value: pages.openAppointment.patientID!,
                            label: patients.get(pages.openAppointment.patientID!)!.title)
                      ]
                    : [],
                strict: true,
                limit: 1,
                placeholder: "Select patient",
              ),
            ),
            const SizedBox(width: 5),
            if (pages.openAppointment.patientID == null)
              AcrylicButton(
                  icon: FluentIcons.add_friend,
                  text: "New patient",
                  onPressed: () {
                    openSinglePatient(
                      context: context,
                      json: {},
                      title: "New Patient",
                      onSave: (patient) {
                        patients.add(patient);
                        pages.openAppointment.patientID = patient.id;
                        appointments.notify();
                      },
                      editing: false,
                    );
                  })
          ]),
        ),
        InfoLabel(
          label: "Operators:",
          child: TagInputWidget(
            suggestions:
                staff.presentAndOperate.map((staff) => TagInputItem(value: staff.id, label: staff.title)).toList(),
            onChanged: (s) {
              pages.openAppointment.operatorsIDs = s.where((x) => x.value != null).map((x) => x.value!).toList();
              state.notify();
            },
            initialValue: pages.openAppointment.operatorsIDs
                .map((id) => TagInputItem(value: id, label: staff.get(id)!.title))
                .toList(),
            onItemTap: (tag) {
              Member? tapped = staff.get(tag.value ?? "");
              Map<String, dynamic> json = tapped != null ? tapped.toJson() : {};
              openSingleMember(
                context: context,
                json: json,
                title: "Staff member Details",
                onSave: staff.modify,
                editing: true,
              );
            },
            strict: true,
            limit: 999,
            placeholder: "Select operators",
          ),
        ),
        Column(
          children: [
            InfoLabel(
              label: "Date:",
              child: DateTimePicker(
                value: pages.openAppointment.date(),
                onChange: (d) {
                  pages.openAppointment.date(d);
                  state.notify();
                },
                buttonText: "Change date",
                buttonIcon: FluentIcons.calendar,
                format: "d MMMM yyyy",
              ),
            ),
            const SizedBox(height: 5),
            if (pages.openAppointment.operators.isNotEmpty &&
                !pages.openAppointment.availableWeekDays.contains(pages.openAppointment.date().weekday))
              const InfoBar(
                title: Text("Attention"),
                content: Text("One of the selected operators might not be available on the selected date."),
                severity: InfoBarSeverity.warning,
              )
          ],
        ),
        InfoLabel(
          label: "Time:",
          child: DateTimePicker(
            value: pages.openAppointment.date(),
            onChange: (d) => pages.openAppointment.date(d),
            buttonText: "Change time",
            pickTime: true,
            buttonIcon: FluentIcons.clock,
            format: "hh:mm a",
          ),
        ),
        InfoLabel(
          label: "Pre-operative notes:",
          child: CupertinoTextField(
            expands: true,
            maxLines: null,
            controller: TextEditingController(text: pages.openAppointment.preOpNotes),
            onChanged: (v) => pages.openAppointment.preOpNotes = v,
            placeholder: "Pre-operative notes",
          ),
        ),
      ],
    ),
    if (editing)
      TabbedModal(
        title: "Operative details",
        icon: FluentIcons.medical_care,
        closable: true,
        actions: actions,
        content: (state) => [
          InfoLabel(
            label: "Post-operative notes",
            child: CupertinoTextField(
              expands: true,
              maxLines: null,
              controller: TextEditingController(text: pages.openAppointment.postOpNotes),
              onChanged: (v) => pages.openAppointment.postOpNotes = v,
              placeholder: "Post-operative notes",
            ),
          ),
          InfoLabel(
            label: "Prescriptions",
            child: TagInputWidget(
              suggestions: appointments.allPrescriptions.map((p) => TagInputItem(value: p, label: p)).toList(),
              onChanged: (s) {
                pages.openAppointment.prescriptions = s.where((x) => x.value != null).map((x) => x.value!).toList();
              },
              initialValue: pages.openAppointment.prescriptions.map((p) => TagInputItem(value: p, label: p)).toList(),
              strict: false,
              limit: 999,
              placeholder: "prescriptions",
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InfoLabel(
                  label: "Price",
                  child: NumberBox(
                    value: pages.openAppointment.price,
                    onChanged: (v) => pages.openAppointment.price = v ?? 0,
                    placeholder: "Price",
                    mode: SpinButtonPlacementMode.inline,
                  ),
                ),
              ),
              Expanded(
                child: InfoLabel(
                  label: "Paid",
                  child: NumberBox(
                    value: pages.openAppointment.paid,
                    onChanged: (v) => pages.openAppointment.paid = v ?? 0,
                    placeholder: "Paid",
                    mode: SpinButtonPlacementMode.inline,
                  ),
                ),
              ),
            ],
          )
        ],
      )
  ]);
}
