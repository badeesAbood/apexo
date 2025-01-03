import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/appointments/single_appointment_modal.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/features/settings/settings_stores.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_widget.dart';
import 'appointment_model.dart';
import 'appointments_store.dart';

class CalendarScreen extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.calendarScreen,
      padding: EdgeInsets.zero,
      content: StreamBuilder(
          stream: appointments.observableObject.stream,
          builder: (context, snapshot) {
            return WeekAgendaCalendar<Appointment>(
              items: appointments.filtered.values.toList(),
              actions: [
                ComboBox<String>(
                  style: const TextStyle(overflow: TextOverflow.ellipsis),
                  items: [
                    ComboBoxItem<String>(
                      value: "",
                      child: Txt(txt("allDoctors")),
                    ),
                    ...doctors.present.values.map((e) {
                      var doctorName = e.title;
                      if (doctorName.length > 20) {
                        doctorName = "${doctorName.substring(0, 17)}...";
                      }
                      return ComboBoxItem(value: e.id, child: Txt(doctorName));
                    }),
                  ],
                  onChanged: appointments.filterByDoctor,
                  value: appointments.doctorId,
                ),
                const SizedBox(width: 5),
                ArchiveToggle(notifier: appointments.notify)
              ],
              startDay: StartingDayOfWeek.values.firstWhere(
                  (v) => v.name == globalSettings.get("start_day_of_wk").value,
                  orElse: () => StartingDayOfWeek.monday),
              initiallySelectedDay: DateTime.now().millisecondsSinceEpoch,
              onSetTime: (item) {
                appointments.set(item);
              },
              onSelect: (item) {
                openSingleAppointment(
                  context: context,
                  title: txt("editAppointment"),
                  json: item.toJson(),
                  onSave: appointments.set,
                  editing: true,
                );
              },
              onAddNew: (selectedDate) {
                openSingleAppointment(
                  context: context,
                  title: txt("addAppointment"),
                  json: {"date": selectedDate.millisecondsSinceEpoch / 60000},
                  onSave: appointments.set,
                  editing: false,
                );
              },
            );
          }),
    );
  }
}
