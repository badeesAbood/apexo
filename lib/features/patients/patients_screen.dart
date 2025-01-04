import 'package:apexo/common_widgets/dialogs/export_patients_dialog.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/appointments/single_appointment_modal.dart';
import 'package:apexo/features/patients/single_patient_modal.dart';
import 'package:apexo/common_widgets/archive_selected.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:apexo/features/patients/patient_model.dart';
import 'package:apexo/features/patients/patients_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import "../../common_widgets/datatable.dart";

// ignore: must_be_immutable
class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.patientsScreen,
      padding: EdgeInsets.zero,
      content: StreamBuilder(
          stream: patients.observableMap.stream,
          builder: (context, snapshot) {
            return DataTable<Patient>(
              items: patients.present.values.toList(),
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
                archiveSelected(patients),
                DataTableAction(
                  callback: (ids) {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ExportPatientsDialog(ids: ids);
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
                        title: txt("addAppointment"),
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
            );
          }),
    );
  }
}
