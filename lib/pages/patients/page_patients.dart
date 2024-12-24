import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/calendar/modal_appointment.dart';
import 'package:apexo/pages/patients/modal_patient.dart';
import 'package:apexo/pages/settings/window_backups.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart' hide TextBox;
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import "../shared/datatable.dart";

// ignore: must_be_immutable
class PatientPage extends ObservingWidget {
  const PatientPage({super.key});

  @override
  getObservableState() {
    return [appointments.observableObject, patients.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.patientsPage,
      padding: EdgeInsets.zero,
      content: DataTable<Patient>(
        items: patients.showing.values.toList(),
        actions: [
          DataTableAction(
            callback: (_) async {
              openSinglePatient(
                context: context,
                json: {},
                editing: false,
                title: txt("addNewPatient"),
                onSave: patients.set,
                showContinue: true,
              );
            },
            icon: FluentIcons.add_friend,
            title: txt("add"),
          ),
          DataTableAction(
            callback: (ids) {
              for (var id in ids) {
                patients.archive(id);
              }
            },
            icon: FluentIcons.archive,
            title: txt("archive"),
          ),
          DataTableAction(
            callback: (ids) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ExportPatients(ids: ids);
                  });
            },
            icon: FluentIcons.guid,
            title: txt("exportSelected"),
          ),
        ],
        furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: patients.notify)],
        onSelect: (item) {
          openSinglePatient(
            context: context,
            json: item.toJson(),
            editing: true,
            title: txt("editPatient"),
            onSave: patients.set,
          );
        },
        itemActions: [
          ItemAction(
            icon: FluentIcons.add_event,
            title: txt("addAppointment"),
            callback: (id) async {
              final patient = patients.get(id);
              if (patient == null) return;
              if (context.mounted) {
                openSingleAppointment(
                  context: context,
                  json: {"patientID": id},
                  title: txt("newAppointment"),
                  onSave: appointments.set,
                  editing: false,
                );
              }
            },
          ),
          ItemAction(
            icon: FluentIcons.phone,
            title: txt("callPatient"),
            callback: (id) {
              final patient = patients.get(id);
              if (patient == null) return;
              launchUrl(Uri.parse('tel:${patient.phone}'));
            },
          ),
          ItemAction(
            icon: FluentIcons.archive,
            title: txt("archive"),
            callback: (id) {
              patients.archive(id);
            },
          ),
        ],
      ),
    );
  }
}

class ExportPatients extends StatefulWidget {
  final List<String> ids;
  const ExportPatients({
    super.key,
    required this.ids,
  });

  @override
  State<ExportPatients> createState() => _ExportPatientsState();
}

class _ExportPatientsState extends State<ExportPatients> {
  late List<Patient?> selected;
  bool name = true;
  bool phoneNumber = true;
  bool age = false;
  bool gender = false;
  bool totalPayments = false;
  String get exportData {
    return selected
        .map(
          (patient) => [
            name ? patient!.title : null,
            phoneNumber ? patient!.phone : null,
            age ? patient!.age : null,
            gender ? patient!.gender : null,
            totalPayments ? patient!.paymentsMade.toString() : null,
          ].where((x) => x != null).join(","),
        )
        .join("\n");
  }

  @override
  void initState() {
    selected = widget.ids.map((id) => patients.get(id)).where((e) => e != null).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(txt("exportSelected")),
          IconButton(icon: const Icon(FluentIcons.cancel), onPressed: () => Navigator.pop(context))
        ],
      ),
      content: selected.isEmpty
          ? InfoBar(
              isIconVisible: true,
              severity: InfoBarSeverity.warning,
              title: Text(txt("noPatientsSelected")),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Checkbox(
                      checked: name,
                      onChanged: (checked) => setState(() => name = checked!),
                      content: Text(txt("name")),
                    ),
                    Checkbox(
                      checked: phoneNumber,
                      onChanged: (checked) => setState(() => phoneNumber = checked!),
                      content: Text(txt("phone")),
                    ),
                    Checkbox(
                      checked: age,
                      onChanged: (checked) => setState(() => age = checked!),
                      content: Text(txt("age")),
                    ),
                    Checkbox(
                      checked: gender,
                      onChanged: (checked) => setState(() => gender = checked!),
                      content: Text(txt("gender")),
                    ),
                    Checkbox(
                      checked: totalPayments,
                      onChanged: (checked) => setState(() => totalPayments = checked!),
                      content: Text(txt("total payments")),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  height: 200,
                  child: CupertinoTextField(
                    maxLines: null,
                    controller: TextEditingController(text: exportData.replaceAll("\n", "\n\n")),
                  ),
                )
              ],
            ),
      style: dialogStyling(false),
      actions: const [CloseButtonInDialog(buttonText: "close")],
    );
  }
}
