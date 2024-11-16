import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/calendar/modal_appointment.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import '../shared/week_calendar.dart';
import '../../../state/stores/appointments/appointment_model.dart';
import '../../../state/stores/appointments/appointments_store.dart';

class Calendar extends ObservingWidget {
  // ignore: prefer_const_constructors_in_immutables
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
        items: appointments.filtered.values.toList(),
        actions: [
          ComboBox<String>(
            style: const TextStyle(overflow: TextOverflow.ellipsis),
            items: [
              const ComboBoxItem<String>(
                value: "",
                child: Text("All operators"),
              ),
              ...staff.present.values.map((e) {
                var doctorName = e.title;
                if (doctorName.length > 20) {
                  doctorName = "${doctorName.substring(0, 17)}...";
                }
                return ComboBoxItem(value: e.id, child: Text(doctorName));
              }),
            ],
            onChanged: appointments.filterByStaff,
            value: appointments.staffId,
          ),
          const SizedBox(width: 5),
          ArchiveToggle(notifier: appointments.notify)
        ],
        startDay: StartingDayOfWeek.values.firstWhere((v) => v.name == globalSettings.get("start_day_of_wk")?.value,
            orElse: () => StartingDayOfWeek.monday),
        initiallySelectedDay: DateTime.now().millisecondsSinceEpoch,
        onSetTime: (item) {
          appointments.set(item);
        },
        onSelect: (item) {
          openSingleAppointment(
            context: context,
            title: "Appointment",
            json: item.toJson(),
            onSave: appointments.set,
            editing: true,
          );
        },
        onAddNew: (selectedDate) {
          openSingleAppointment(
            context: context,
            title: "Add new",
            json: {"date": selectedDate.millisecondsSinceEpoch},
            onSave: appointments.set,
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