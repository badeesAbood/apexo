import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/doctors/modal_doctor.dart';
import 'package:apexo/state/stores/doctors/doctors_store.dart';
import 'package:apexo/state/stores/doctors/doctor_model.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import "../shared/datatable.dart";

class DoctorsPage extends ObservingWidget {
  const DoctorsPage({super.key});

  @override
  getObservableState() {
    return [doctors.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.doctorsPage,
      padding: EdgeInsets.zero,
      content: DataTable<Doctor>(
        items: doctors.showing.values.toList(),
        actions: [
          DataTableAction(
            callback: (_) => openSingleDoctor(
              context: context,
              json: {},
              title: "${txt("add")} ${txt("doctor")}",
              onSave: doctors.set,
              editing: false,
            ),
            icon: FluentIcons.medical,
            title: txt("add"),
          ),
          DataTableAction(
            callback: (ids) {
              for (var id in ids) {
                doctors.archive(id);
              }
            },
            icon: FluentIcons.archive,
            title: txt("archiveSelected"),
          )
        ],
        furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: doctors.notify)],
        onSelect: (item) => openSingleDoctor(
          context: context,
          json: item.toJson(),
          title: "${txt("edit")} ${txt("doctor")}",
          onSave: doctors.set,
          editing: true,
        ),
      ),
    );
  }
}
