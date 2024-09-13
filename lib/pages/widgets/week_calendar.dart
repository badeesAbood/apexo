import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show showTimePicker, TimeOfDay, FloatingActionButton;
import 'package:intl/intl.dart';
import '../../backend/observable/model.dart';
import '../../backend/utils/colors_without_yellow.dart';
import '../../backend/utils/round.dart';
import 'acrylic_title.dart';
import '../../state/stores/appointments/appointments_store.dart';
import 'package:table_calendar/table_calendar.dart';

class WeekAgendaCalendar<Item extends AgendaItem> extends StatefulWidget {
  final List<Item> items;
  final String startDay;
  final String noAppointmentsMessage;
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
    this.noAppointmentsMessage = "No appointments for this day",
  });

  @override
  WeekAgendaCalendarState<Item> createState() => WeekAgendaCalendarState<Item>();
}

class WeekAgendaCalendarState<Item extends AgendaItem> extends State<WeekAgendaCalendar<Item>> {
  CalendarFormat calendarFormat = CalendarFormat.week;
  late DateTime selectedDate;
  final now = DateTime.now();

  StartingDayOfWeek get startingDayOfWeek {
    var match = StartingDayOfWeek.values.where((v) => v.name.contains(widget.startDay));
    if (match.isEmpty) {
      return StartingDayOfWeek.monday;
    } else {
      return match.first;
    }
  }

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
    return widget.items.where((item) => isSameDay(day, item.date)).toList();
  }

  List<Item> _getItemsForSelectedDay() {
    return widget.items.where((item) => isSameDay(selectedDate, item.date)).toList();
  }

  bool isSameDay(DateTime day1, DateTime day2) {
    return day1.day == day2.day && day1.month == day2.month && day1.year == day2.year;
  }

  @override
  Widget build(BuildContext context) {
    var itemsForSelectedDay = _getItemsForSelectedDay();
    return Stack(
      children: [
        Column(
          children: [
            _buildCalendar(),
            const SizedBox(height: 1),
            _buildCurrentDayTitleBar(),
            itemsForSelectedDay.isEmpty ? _buildEmptyDayMessage() : _buildAppointmentsList(itemsForSelectedDay),
          ],
        ),
        _buildFloatingButton()
      ],
    );
  }

  Widget _buildFloatingButton() {
    return Positioned(
      bottom: 15,
      right: 15,
      child: FloatingActionButton.extended(
        onPressed: () {
          widget.onAddNew(selectedDate);
        },
        label: Text("Add new"),
        icon: const Icon(FluentIcons.add_event),
      ),
    );
  }

  Widget _buildCalendar() {
    return Acrylic(
      elevation: 50,
      child: Container(
          constraints: BoxConstraints(maxHeight: calendarHeight),
          child: TableCalendar(
            firstDay: now.subtract(const Duration(days: 9999)),
            focusedDay: selectedDate,
            lastDay: now.add(const Duration(days: 9999)),
            daysOfWeekVisible: true,
            rowHeight: 30,
            startingDayOfWeek: startingDayOfWeek,
            pageJumpingEnabled: true,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            shouldFillViewport: true,
            calendarFormat: calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                calendarFormat = format;
              });
            },
            availableCalendarFormats:
                Map.from({CalendarFormat.twoWeeks: "2W", CalendarFormat.month: "M", CalendarFormat.week: "W"}),
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
              headerTitleBuilder: (context, day) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: Text(
                        DateFormat('MMMM yyyy').format(day),
                      ),
                    ),
                    const Divider(size: 20, direction: Axis.vertical),
                    if (!isSameDay(day, DateTime.now()))
                      IconButton(
                        onPressed: _goToToday,
                        iconButtonMode: IconButtonMode.large,
                        icon: Row(
                          children: [Icon(FluentIcons.goto_today), SizedBox(width: 5), Text("Today")],
                        ),
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
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
                    child: Text(
                      day.day.toString(),
                    ),
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
                      day.day.toString(),
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
                      day.day.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                return events.isEmpty
                    ? null
                    : Text(
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
                                  color: colorsWithoutYellow[day.weekday - 1]
                                      .withOpacity(min(roundToPrecision(events.length / 30, 2), 1)),
                                  blurRadius: 1),
                            )
                          ],
                        ),
                      );
              },
            ),
            onDaySelected: (newDate, focusedDay) {
              setState(() => selectedDate = newDate);
            },
          )),
    );
  }

  Widget _buildAppointmentsList(List<Item> itemsForSelectedDay) {
    var sortedItems = [...itemsForSelectedDay]
      ..sort((a, b) => a.date.millisecondsSinceEpoch - b.date.millisecondsSinceEpoch);
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedItems.length,
        itemBuilder: (context, index) {
          Item item = sortedItems[index];
          return Padding(
            padding: const EdgeInsets.all(1),
            child: AppointmentTile<Item>(
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
        title: Text(widget.noAppointmentsMessage),
      ),
    );
  }

  Widget _buildCurrentDayTitleBar() {
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
            Text(DateFormat("d MMMM yyyy").format(selectedDate)),
            Checkbox(
              checked: appointments.showArchived(),
              onChanged: appointments.showArchivedChanged,
              style: const CheckboxThemeData(icon: FluentIcons.archive),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleOnAcrylic extends StatelessWidget {
  const TitleOnAcrylic({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [
        Shadow(
          blurRadius: 7,
          color: Colors.grey.withOpacity(0.3),
          offset: const Offset(0, 0),
        ),
        Shadow(
          blurRadius: 0,
          color: Colors.grey.withOpacity(0.2),
          offset: const Offset(1, 1),
        ),
      ]),
    );
  }
}

class AppointmentTile<Item extends AgendaItem> extends StatelessWidget {
  const AppointmentTile({
    super.key,
    required this.item,
    required this.onSetTime,
    required this.onSelect,
  });

  final Item item;
  final void Function(Item item) onSetTime;
  final void Function(Item item) onSelect;

  @override
  Widget build(BuildContext context) {
    return Acrylic(
      child: ListTile(
        title: AcrylicTitle(item: item),
        subtitle: item.subtitle.isNotEmpty ? Text(item.subtitle) : null,
        leading: const Row(children: [
          Icon(FluentIcons.date_time),
          SizedBox(width: 8),
          Divider(direction: Axis.vertical, size: 40),
        ]),
        onPressed: () {
          onSelect(item);
        },
        trailing: Row(
          children: [
            const Divider(direction: Axis.vertical, size: 40),
            const SizedBox(width: 5),
            IconButton(
              onPressed: () async {
                TimeOfDay? res = await showTimePicker(
                    context: context, initialTime: TimeOfDay(hour: item.date.hour, minute: item.date.minute));
                if (res != null) {
                  item.date = DateTime(item.date.year, item.date.month, item.date.day, res.hour, res.minute);
                  onSetTime(item);
                }
              },
              icon: Row(
                children: [
                  const Icon(FluentIcons.clock),
                  const SizedBox(width: 8),
                  Text(DateFormat('hh:mm a').format(item.date)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaItem extends Model {
  DateTime date = DateTime.now();

  String get subtitle {
    return date.toString();
  }

  AgendaItem.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    date = json["date"] != null ? DateTime.fromMillisecondsSinceEpoch(json["date"]) : date;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = AgendaItem.fromJson({});
    if (date.compareTo(d.date) != 0) json['date'] = date.millisecondsSinceEpoch;
    return json;
  }
}
