import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/calendar/modal_appointment.dart';
import 'package:apexo/pages/shared/archive_selected.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/doctors/modal_doctor.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/doctors/doctors_store.dart';
import 'package:apexo/state/stores/doctors/doctor_model.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
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
              showContinue: true,
            ),
            icon: FluentIcons.medical,
            title: txt("add"),
          ),
          archiveSelected(doctors)
        ],
        furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: doctors.notify)],
        onSelect: (item) => openSingleDoctor(
          context: context,
          json: item.toJson(),
          title: "${txt("edit")} ${txt("doctor")}",
          onSave: doctors.set,
          editing: true,
        ),
        itemActions: [
          ItemAction(
            icon: FluentIcons.add_event,
            title: txt("addAppointment"),
            callback: (id) async {
              openSingleAppointment(
                context: context,
                json: {
                  "operatorsIDs": [id]
                },
                title: txt("addAppointment"),
                onSave: appointments.set,
                editing: false,
              );
            },
          ),
          ItemAction(
            icon: FluentIcons.mail,
            title: txt("emailDoctor"),
            callback: (id) {
              final doctor = doctors.get(id);
              if (doctor == null) return;
              launchUrl(Uri.parse('mailto:${doctor.email}'));
            },
          ),
          ItemAction(
            icon: FluentIcons.archive,
            title: txt("archive"),
            callback: (id) {
              doctors.archive(id);
            },
          ),
        ],
      ),
    );
  }
}
