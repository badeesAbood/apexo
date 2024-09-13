import 'package:fluent_ui/fluent_ui.dart';
import 'date_time_picker.dart';
import 'tabbed_modal.dart';
import '../../state/stores/appointments/appointment_model.dart';

showAppointmentEditor(BuildContext context, String title, Appointment target, List<TabAction> actions) {
  showTabbedModal(context: context, tabs: [
    TabbedModal(
      title: title,
      icon: FluentIcons.add_event,
      closable: true,
      actions: actions,
      content: () => [
        InfoLabel(
          label: "Title",
          child: TextBox(
            onChanged: (value) => target.title = value,
            controller: TextEditingController(text: target.title),
          ),
        ),
        InfoLabel(
          label: "Date",
          child: DateTimePicker(
            value: target.date,
            onChange: (d) => target.date = d,
            buttonText: "Change date",
            buttonIcon: FluentIcons.calendar,
            format: "d MMMM yyyy",
          ),
        ),
        InfoLabel(
          label: "Time",
          child: DateTimePicker(
            value: target.date,
            onChange: (d) => target.date = d,
            buttonText: "Change time",
            pickTime: true,
            buttonIcon: FluentIcons.clock,
            format: "hh:mm a",
          ),
        ),
      ],
    )
  ]);
}
