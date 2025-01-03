import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/common_widgets/acrylic_button.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show showTimePicker, showDatePicker, TimeOfDay;
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class DateTimePicker extends StatefulWidget {
  DateTime value;
  final bool pickTime;
  final String format;
  final String buttonText;
  final IconData buttonIcon;
  final Function(DateTime value) onChange;
  DateTimePicker({
    super.key,
    required this.value,
    required this.onChange,
    this.pickTime = false,
    this.format = "dd/MM/yyyy",
    this.buttonIcon = FluentIcons.time_entry,
    this.buttonText = "Change date",
  });

  @override
  State<DateTimePicker> createState() => DateTimePickerState();
}

class DateTimePickerState extends State<DateTimePicker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pick,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Txt(DateFormat(widget.format, locale.s.$code).format(widget.value)),
            AcrylicButton(icon: widget.buttonIcon, text: widget.buttonText, onPressed: pick)
          ],
        ),
      ),
    );
  }

  pick() async {
    DateTime selected = widget.value;

    if (widget.pickTime) {
      TimeOfDay time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: widget.value.hour, minute: widget.value.minute),
          ) ??
          TimeOfDay(hour: selected.hour, minute: selected.minute);
      selected = DateTime(selected.year, selected.month, selected.day, time.hour, time.minute);
    } else {
      selected = await showDatePicker(
            context: context,
            initialDate: widget.value,
            firstDate: DateTime.now().subtract(const Duration(days: 9999)),
            lastDate: DateTime.now().add(const Duration(days: 9999)),
          ) ??
          selected;
    }

    setState(() {
      widget.onChange(selected);
      widget.value = selected;
    });
  }
}
