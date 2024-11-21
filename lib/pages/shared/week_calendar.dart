import 'dart:math';

import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Card;
import 'package:flutter/material.dart' show showTimePicker, TimeOfDay, Card;
import 'package:intl/intl.dart' as intl;
import '../../backend/observable/model.dart';
import '../../backend/utils/colors_without_yellow.dart';
import '../../backend/utils/round.dart';
import 'acrylic_title.dart';
import '../../state/stores/appointments/appointments_store.dart';
import 'package:table_calendar/table_calendar.dart';

class WeekAgendaCalendar<Item extends AgendaItem> extends StatefulWidget {
  final List<Item> items;
  final List<Widget>? actions;
  final StartingDayOfWeek startDay;
  final int initiallySelectedDay;
  final void Function(DateTime date) onAddNew;
  final void Function(Item item) onSetTime;
  final void Function(Item item) onSelect;

  const WeekAgendaCalendar({
    super.key,
    required this.items,
    required this.startDay,
    required this.initiallySelectedDay,
    required this.onAddNew,
    required this.onSetTime,
    required this.onSelect,
    this.actions,
  });

  @override
  WeekAgendaCalendarState<Item> createState() => WeekAgendaCalendarState<Item>();
}

class WeekAgendaCalendarState<Item extends AgendaItem> extends State<WeekAgendaCalendar<Item>> {
  CalendarFormat calendarFormat = CalendarFormat.week;
  late DateTime selectedDate;
  final now = DateTime.now();

  double get calendarHeight {
    switch (calendarFormat) {
      case CalendarFormat.month:
        return 300;
      case CalendarFormat.twoWeeks:
        return 170;
      default:
        return 130;
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.initiallySelectedDay);
  }

  void _goToToday() {
    setState(() {
      selectedDate = now;
    });
  }

  List<Item> _getItemsForDay(DateTime day) {
    return widget.items.where((item) => isSameDay(day, item.date())).toList();
  }

  List<Item> _getItemsForSelectedDay() {
    return widget.items.where((item) => isSameDay(selectedDate, item.date())).toList();
  }

  bool isSameDay(DateTime day1, DateTime day2) {
    return day1.day == day2.day && day1.month == day2.month && day1.year == day2.year;
  }

  @override
  Widget build(BuildContext context) {
    var itemsForSelectedDay = _getItemsForSelectedDay();
    return Column(
      children: [
        Acrylic(
          elevation: 150,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () => widget.onAddNew(selectedDate),
                    icon: Row(
                      children: [
                        const Icon(FluentIcons.add_event, size: 17),
                        const SizedBox(width: 10),
                        Text(txt("add"))
                      ],
                    )),
                Row(
                  children: widget.actions ?? [],
                ),
              ],
            ),
          ),
        ),
        _buildCalendar(),
        const SizedBox(height: 1),
        _buildCurrentDayTitleBar(),
        itemsForSelectedDay.isEmpty ? _buildEmptyDayMessage() : _buildAppointmentsList(itemsForSelectedDay),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
        constraints: BoxConstraints(maxHeight: calendarHeight),
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          child: _buildTableCalendar(),
        ));
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      firstDay: now.subtract(const Duration(days: 9999)),
      lastDay: now.add(const Duration(days: 9999)),
      focusedDay: selectedDate,
      daysOfWeekVisible: true,
      rowHeight: 30,
      startingDayOfWeek: widget.startDay,
      pageJumpingEnabled: true,
      selectedDayPredicate: (day) => isSameDay(day, selectedDate),
      shouldFillViewport: true,
      calendarFormat: calendarFormat,
      onFormatChanged: (format) {
        setState(() {
          calendarFormat = format;
        });
      },
      availableCalendarFormats: Map.from({
        CalendarFormat.twoWeeks: txt("twoWeeksAbbr"),
        CalendarFormat.month: txt("monthAbbr"),
        CalendarFormat.week: txt("weekAbbr")
      }),
      eventLoader: (day) => _getItemsForDay(day),
      headerStyle: HeaderStyle(
          formatButtonShowsNext: false,
          formatButtonTextStyle: const TextStyle(color: Colors.white),
          formatButtonDecoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.grey.toAccentColor().lightest,
                Colors.grey.toAccentColor().light,
              ]),
              borderRadius: BorderRadius.circular(4))),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) => Center(
          child: Text(
            intl.DateFormat("EE", locale.s.$code).format(day),
          ),
        ),
        headerTitleBuilder: (context, day) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Center(
                child: Text(
                  intl.DateFormat('MMMM yyyy', locale.s.$code).format(day),
                ),
              ),
              const Divider(size: 20, direction: Axis.vertical),
              if (!isSameDay(day, DateTime.now()))
                IconButton(
                  onPressed: _goToToday,
                  iconButtonMode: IconButtonMode.large,
                  icon: Row(
                    children: [const Icon(FluentIcons.goto_today), const SizedBox(width: 5), Text(txt("today"))],
                  ),
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: colorsWithoutYellow[DateTime.now().weekday - 1].withOpacity(1)))),
                  ),
                ),
            ],
          );
        },
        defaultBuilder: (context, day, focusedDay) {
          return Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.grey.withOpacity(0.02), Colors.grey.withOpacity(0.05)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(intl.DateFormat("d", locale.s.$code).format(day)),
            ),
          );
        },
        todayBuilder: (context, day, focusedDay) {
          return Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                colorsWithoutYellow[day.weekday - 1].withOpacity(0.1),
                colorsWithoutYellow[day.weekday - 1].withOpacity(0.2)
              ]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                intl.DateFormat("d", locale.s.$code).format(day),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        selectedBuilder: (context, day, focusedDay) {
          return Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [colorsWithoutYellow[day.weekday - 1], colorsWithoutYellow[day.weekday - 1].lighter]),
                shape: BoxShape.circle,
                boxShadow: kElevationToShadow[2]),
            child: Center(
              child: Text(
                intl.DateFormat("d", locale.s.$code).format(day),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        markerBuilder: (context, day, events) {
          return events.isEmpty ? null : _buildEventsNum(events, day);
        },
      ),
      onDaySelected: (newDate, focusedDay) {
        setState(() => selectedDate = newDate);
      },
    );
  }

  Text _buildEventsNum(List<Object?> events, DateTime day) {
    return Text(
      events.length.toString(),
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        fontSize: 10,
        color: Colors.white,
        shadows: [
          ...kElevationToShadow[1]!,
          Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 0)),
          Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 0)),
          ...List.generate(
            10,
            (index) => Shadow(
                color:
                    colorsWithoutYellow[day.weekday - 1].withOpacity(min(roundToPrecision(events.length / 30, 2), 1)),
                blurRadius: 1),
          )
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(List<Item> itemsForSelectedDay) {
    var sortedItems = [...itemsForSelectedDay]
      ..sort((a, b) => a.date().millisecondsSinceEpoch - b.date().millisecondsSinceEpoch);
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedItems.length,
        itemBuilder: (context, index) {
          Item item = sortedItems[index];
          return Padding(
            padding: const EdgeInsets.all(1),
            child: _buildAppointmentTile(
              item: item,
              onSetTime: (item) {
                widget.onSetTime(item);
              },
              onSelect: (item) {
                widget.onSelect(item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyDayMessage() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InfoBar(
        isIconVisible: true,
        severity: InfoBarSeverity.warning,
        title: Text(txt("noAppointmentsForThisDay")),
      ),
    );
  }

  Widget _buildCurrentDayTitleBar() {
    final df = localSettings.dateFormat.startsWith("d") == true ? "dd MMMM" : "MMMM dd";
    return Acrylic(
      child: Container(
        decoration: BoxDecoration(
            border: BorderDirectional(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
            gradient: LinearGradient(colors: [
              colorsWithoutYellow[selectedDate.weekday - 1].darkest.withOpacity(0.08),
              colorsWithoutYellow[selectedDate.weekday - 1].withOpacity(0),
            ])),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 45,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(intl.DateFormat("$df / yyyy", locale.s.$code).format(selectedDate)),
          ],
        ),
      ),
    );
  }

  _buildAppointmentTile({
    required Item item,
    required void Function(Item item) onSetTime,
    required void Function(Item item) onSelect,
  }) {
    return Acrylic(
      child: ListTile(
        title: AcrylicTitle(item: item),
        subtitle: item.subtitleLine1.isNotEmpty ? Text(item.subtitleLine1, overflow: TextOverflow.ellipsis) : null,
        leading: Row(children: [
          Column(
            children: [
              Checkbox(
                  checked: item.isDone(),
                  onChanged: (checked) {
                    item.isDone(checked ?? false);
                    appointments.set(item as Appointment);
                  }),
            ],
          ),
          const SizedBox(width: 8),
          const Divider(direction: Axis.vertical, size: 40),
        ]),
        onPressed: () {
          onSelect(item);
        },
        trailing: Row(
          children: [
            const Divider(direction: Axis.vertical, size: 40),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () async {
                    TimeOfDay? res = await showTimePicker(
                        context: context, initialTime: TimeOfDay(hour: item.date().hour, minute: item.date().minute));
                    if (res != null) {
                      item.date(DateTime(item.date().year, item.date().month, item.date().day, res.hour, res.minute));
                      onSetTime(item);
                    }
                  },
                  icon: Row(
                    children: [
                      const Icon(FluentIcons.clock),
                      const SizedBox(width: 5),
                      Text(intl.DateFormat('hh:mm a', locale.s.$code).format(item.date())),
                    ],
                  ),
                ),
                if (item.subtitleLine2.isNotEmpty)
                  SizedBox(
                      width: 75,
                      child: Text(
                        item.subtitleLine2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaItem extends Model {
  final date = ObservableState(DateTime.now());
  final isDone = ObservableState(false);

  String get subtitleLine1 {
    return date.toString();
  }

  String get subtitleLine2 {
    return date.toString();
  }

  AgendaItem.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    date(json["date"] != null ? DateTime.fromMillisecondsSinceEpoch(json["date"]) : date());
    isDone(json["isDone"] ?? isDone());
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = AgendaItem.fromJson({});
    if (date().compareTo(d.date()) != 0) json['date'] = date().millisecondsSinceEpoch;
    if (isDone() != d.isDone()) json['isDone'] = isDone();
    return json;
  }
}
