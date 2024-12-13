import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/bar.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/line.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/pie.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/radar.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/stacked.dart';
import 'package:apexo/pages/stats/window_range_control.dart';
import 'package:apexo/state/charts.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:apexo/state/stores/doctors/doctors_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

class PageStats extends ObservingWidget {
  const PageStats({super.key});

  final List<IconData> _icons = const [
    FluentIcons.calendar_day,
    FluentIcons.calendar_week,
    FluentIcons.calendar,
    FluentIcons.calendar_agenda,
    FluentIcons.calendar_year,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildHeader(context),
      RangeControl(color: _color, textStyle: _textStyle, icons: _icons),
      const Divider(size: 1500),
      Expanded(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                chartWindow(
                  "${txt("appointmentsPer")} ${txt(chartsState.intervalString.toLowerCase())}",
                  "${txt("total")}: ${chartsState.filteredAppointments.length} ${txt("appointments")} ${txt("in_Duration_")} ${chartsState.periods.length} ${txt(chartsState.intervalString.toLowerCase())}",
                  StyledBarChart(
                    labels: chartsState.periods.map((p) => p.label).toList(),
                    yAxis: chartsState.groupedAppointments.map((g) => g.length.toDouble()).toList(),
                  ),
                  FluentIcons.date_time,
                ),
                chartWindow(
                  "${txt("paymentsAndExpensesPer")} ${txt(chartsState.intervalString.toLowerCase())}",
                  "${txt("total")}: ${chartsState.groupedPayments.reduce((v, e) => v += e)} ${globalSettings.get("currency_______").value} ${txt("in_Duration_")} ${chartsState.periods.length} ${txt(chartsState.intervalString.toLowerCase())}",
                  StyledLineChart(
                    labels: chartsState.periods.map((p) => p.label).toList(),
                    datasets: [chartsState.groupedPayments.toList(), chartsState.groupedExpenses.toList()],
                    datasetLabels: [
                      "${txt("payments")} ${globalSettings.get("currency_______").value}",
                      "${txt("expenses")} ${globalSettings.get("currency_______").value}"
                    ],
                  ),
                  FluentIcons.currency,
                ),
                chartWindow(
                  "${txt("newPatientsPer")} ${txt(chartsState.intervalString.toLowerCase())}",
                  "${txt("acquiredPatientsIn")} ${chartsState.periods.length} ${txt(chartsState.intervalString.toLowerCase())}",
                  StyledLineChart(
                    labels: chartsState.periods.map((p) => p.label).toList(),
                    datasets: [chartsState.newPatients.toList()],
                    datasetLabels: [txt("patients")],
                  ),
                  FluentIcons.people,
                ),
                chartWindow(
                  "${txt("doneMissedPer")} ${txt(chartsState.intervalString.toLowerCase())}",
                  "${txt("doneAndMissedAppointmentsIn")} ${chartsState.periods.length} ${txt(chartsState.intervalString.toLowerCase())}",
                  StyledStackedChart(
                    labels: chartsState.periods.map((p) => p.label).toList(),
                    datasets: chartsState.doneAndMissedAppointments,
                    datasetLabels: [txt("done"), txt("missed")],
                  ),
                  FluentIcons.check_list,
                ),
                chartWindow(
                  txt("timeOfDay"),
                  txt("distributionOfAppointments"),
                  StyledRadarChart(
                    data: [chartsState.timeOfDayDistribution],
                    labels: List.generate(
                        24, (index) => DateFormat("hh a", locale.s.$code).format(DateTime(0, 0, 0, index))),
                  ),
                  FluentIcons.clock,
                ),
                chartWindow(
                  txt("dayOfWeek"),
                  txt("distributionOfAppointments"),
                  StyledRadarChart(
                    data: [chartsState.dayOfWeekDistribution],
                    labels: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                        .map((e) => txt(e))
                        .toList(),
                  ),
                  FluentIcons.calendar_day,
                ),
                chartWindow(
                  txt("dayOfMonth"),
                  txt("distributionOfAppointments"),
                  StyledRadarChart(
                      data: [chartsState.dayOfMonthDistribution],
                      labels: List.generate(31, (index) => (index + 1).toString())),
                  FluentIcons.calendar_day,
                ),
                chartWindow(
                  txt("monthOfYear"),
                  txt("distributionOfAppointments"),
                  StyledRadarChart(
                    data: [chartsState.monthOfYearDistribution],
                    labels: const [
                      "January",
                      "February",
                      "March",
                      "April",
                      "May",
                      "June",
                      "July",
                      "August",
                      "September",
                      "October",
                      "November",
                      "December"
                    ].map((e) => txt(e)).toList(),
                  ),
                  FluentIcons.calendar_year,
                ),
                chartWindow(
                  txt("patientsGender"),
                  txt("maleAndFemalePatients"),
                  StyledPie(data: {
                    txt("female"): chartsState.femaleMale[0].toDouble(),
                    txt("male"): chartsState.femaleMale[1].toDouble(),
                  }),
                  FluentIcons.people_external_share,
                ),
              ],
            )
          ],
        ),
      ),
    ]);
  }

  SizedBox chartWindow(String title, String subtitle, Widget chart, [IconData icon = FluentIcons.chart]) {
    return SizedBox(
      width: 600,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Acrylic(
          blurAmount: 20,
          elevation: 10,
          luminosityAlpha: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Container(
            color: Colors.white.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 10, 7),
                  child: Row(
                    children: [
                      Icon(icon),
                      const SizedBox(width: 10),
                      const Divider(size: 20, direction: Axis.vertical),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 15, color: Colors.grey.withOpacity(0.7)),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.7)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(size: 600),
                SizedBox(
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: chart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Acrylic _buildHeader(BuildContext context) {
    return Acrylic(
      elevation: 150,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPickRangeButton(context),
            _buildFarItems(),
          ],
        ),
      ),
    );
  }

  Row _buildFarItems() {
    return Row(
      children: [
        _buildMemberFilter(),
        const SizedBox(width: 5),
        ArchiveToggle(notifier: chartsState.notify),
      ],
    );
  }

  ComboBox<String> _buildMemberFilter() {
    return ComboBox<String>(
      style: const TextStyle(overflow: TextOverflow.ellipsis),
      items: [
        ComboBoxItem<String>(
          value: "",
          child: Text(txt("allDoctors")),
        ),
        ...doctors.present.values.map((e) {
          var doctorName = e.title;
          if (doctorName.length > 20) {
            doctorName = "${doctorName.substring(0, 17)}...";
          }
          return ComboBoxItem(value: e.id, child: Text(doctorName));
        }),
      ],
      onChanged: chartsState.filterByDoctor,
      value: chartsState.doctorID,
    );
  }

  IconButton _buildPickRangeButton(BuildContext context) {
    return IconButton(
      icon: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            FluentIcons.public_calendar,
            size: 17,
          ),
          const SizedBox(width: 5),
          Text(txt("pickRange"))
        ],
      ),
      onPressed: () => chartsState.rangePicker(context),
    );
  }

  @override
  getObservableState() {
    return [chartsState];
  }

  TextStyle get _textStyle => TextStyle(
        color: _color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  Color get _color => Colors.grey.withOpacity(0.5);
}
