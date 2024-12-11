import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/patients/modal_patient.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart' hide TextBox;
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
          )
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
      ),
    );
  }
}
