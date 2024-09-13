import 'package:fluent_ui/fluent_ui.dart';
import './widgets/tabbed_modal.dart';
import './widgets/appointment_editor.dart';
import './widgets/archive_button.dart';
import './widgets/week_calendar.dart';
import '../../state/stores/appointments/appointment_model.dart';
import '../../state/stores/appointments/appointments_store.dart';

// ignore: must_be_immutable
class Calendar extends StatelessWidget {
  Calendar({super.key});

  Appointment newAppointment = Appointment.fromJson({});
  Appointment editAppointment = Appointment.fromJson({});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: WeekAgendaCalendar<Appointment>(
        items: appointments.present,
        startDay: "saturday",
        initiallySelectedDay: DateTime.now().millisecondsSinceEpoch,
        onSetTime: (item) {
          appointments.modify(item);
        },
        onSelect: (item) {
          editAppointment = Appointment.fromJson(item.toJson());
          showAppointmentEditor(context, "Edit", editAppointment, [
            archiveButton(item, appointments),
            TabAction(
              text: "Save appointment",
              icon: FluentIcons.save,
              callback: () {
                appointments.modify(editAppointment);
                return true;
              },
            ),
          ]);
        },
        onAddNew: (selectedDate) {
          newAppointment = Appointment.fromJson({});
          newAppointment.date = selectedDate;
          showAppointmentEditor(context, "Add new", newAppointment, [
            TabAction(
                text: "Add appointment",
                callback: () {
                  appointments.add(newAppointment);
                  return true;
                },
                icon: FluentIcons.add_event)
          ]);
        },
      ),
    );
  }
}
