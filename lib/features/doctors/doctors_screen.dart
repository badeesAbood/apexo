import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/appointments/single_appointment_modal.dart';
import 'package:apexo/common_widgets/archive_selected.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/features/doctors/single_doctor_modal.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/features/doctors/doctor_model.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import "../../common_widgets/datatable.dart";

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.doctorsScreen,
      padding: EdgeInsets.zero,
      content: StreamBuilder(
          stream: doctors.observableObject.stream,
          builder: (context, snapshot) {
            return DataTable<Doctor>(
              items: doctors.present.values.toList(),
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
            );
          }),
    );
  }
}
