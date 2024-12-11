import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/bar.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/line.dart';
import 'package:apexo/state/charts.dart';
import 'package:apexo/state/permissions.dart';
import 'package:apexo/state/state.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

class PageDashboard extends ObservingWidget {
  const PageDashboard({super.key});

  List<Appointment> get thisMonthAppointments {
    final DateTime now = DateTime.now();
    List<Appointment> res = [];
    for (var appointment in appointments.present.values) {
      if (appointment.date().year != now.year) continue;
      if (appointment.date().month != now.month) continue;
      res.add(appointment);
    }
    return res..sort((a, b) => a.date().compareTo(b.date()));
  }

  List<Appointment> get todayAppointments {
    final DateTime now = DateTime.now();
    List<Appointment> res = [];
    for (var appointment in thisMonthAppointments) {
      if (appointment.date().day != now.day) continue;
      res.add(appointment);
    }
    return res..sort((a, b) => a.date().compareTo(b.date()));
  }

  double get paymentsToday {
    double res = 0;
    for (var appointment in todayAppointments) {
      res += appointment.paid;
    }
    return res;
  }

  int get newPatientsToday {
    int res = 0;
    for (var appointment in todayAppointments) {
      if (appointment.firstAppointmentForThisPatient == true) res++;
    }
    return res;
  }

  String get currentName {
    if (state.currentMember == null) return "";
    if (state.currentMember!.title.length > 20) return "${state.currentMember!.title.substring(0, 17)}...";
    return state.currentMember?.title ?? "";
  }

  String get mode {
    return state.isAdmin
        ? txt("modeAdmin")
        : state.isOnline
            ? txt("modeUser")
            : txt("modeOffline");
  }

  String get dashboardMessage {
    final onceStable = state.isOnline ? "" : " ${txt("onceConnectionIsStable")}.";

    final restriction = (state.isAdmin && state.isOnline) ? txt("unRestrictedAccess") : txt("restrictedAccess");

    return "${txt("youAreCurrentlyIn")} $mode ${txt("mode")}. ${txt("youHave")} $restriction.$onceStable";
  }

  @override
  Widget build(BuildContext context) {
    return Column(key: WK.dashboardPage, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Icon(FluentIcons.medical),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${txt("hello")}, $currentName",
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  DateFormat("MMMM d yyyy, hh:mm:a", locale.s.$code).format(DateTime.now()),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
      const Divider(size: 1300),
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
        child: InfoBar(
          title: Text(mode),
          severity: state.isAdmin ? InfoBarSeverity.success : InfoBarSeverity.warning,
          content: Text(dashboardMessage),
        ),
      ),
      if (permissions.list[5] || state.isAdmin) ...[buildTopSquares(), buildDashboardCharts()]
    ]);
  }

  Expanded buildDashboardCharts() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        child: TabView(
          currentIndex: openTab(),
          closeButtonVisibility: CloseButtonVisibilityMode.never,
          header: const SizedBox(width: 5),
          footer: IconButton(
            icon: Row(
              children: [const Icon(FluentIcons.chart), const SizedBox(width: 5), Text(txt("fullStats"))],
            ),
            onPressed: () => pages.navigate(pages.getByIdentifier("statistics")!),
          ),
          onChanged: (value) => openTab(value),
          tabs: [
            Tab(
              text: Text(txt("appointments")),
              icon: const Icon(FluentIcons.calendar),
              closeIcon: null,
              outlineColor: Colors.grey.withOpacity(0.1),
              body: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    Expanded(
                        child: StyledBarChart(
                      labels: chartsState.periods.map((p) => p.label).toList(),
                      yAxis: chartsState.groupedAppointments.map((g) => g.length.toDouble()).toList(),
                    ))
                  ]),
                ),
              ),
            ),
            Tab(
              text: Text(txt("payments")),
              icon: const Icon(FluentIcons.money),
              closeIcon: null,
              outlineColor: Colors.grey.withOpacity(0.1),
              body: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                  child: Column(children: [
                    Expanded(
                        child: StyledLineChart(
                      labels: chartsState.periods.map((p) => p.label).toList(),
                      datasets: [chartsState.groupedPayments.toList()],
                      datasetLabels: ["Payments in ${globalSettings.get("currency_______")?.value}"],
                    ))
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView buildTopSquares() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            dashboardSquare(
              Colors.purple,
              FluentIcons.goto_today,
              todayAppointments.length.toString(),
              txt("appointmentsToday"),
            ),
            dashboardSquare(
              Colors.blue,
              FluentIcons.people,
              newPatientsToday.toString(),
              txt("newPatientsToday"),
            ),
            dashboardSquare(
              Colors.teal,
              FluentIcons.money,
              paymentsToday.toStringAsFixed(2),
              txt("paymentsMadeToday"),
            ),
          ],
        ),
      ),
    );
  }

  Padding dashboardSquare(AccentColor color, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Acrylic(
        elevation: 50,
        luminosityAlpha: 1,
        blurAmount: 80,
        tintAlpha: 0.9,
        tint: color,
        shadowColor: color,
        child: SizedBox(
          width: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: color,
                    ),
                    ...const [
                      SizedBox(width: 10),
                      Divider(size: 40, direction: Axis.vertical),
                      SizedBox(width: 10),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color.dark),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                              fontSize: 13, color: color.darkest, fontStyle: FontStyle.italic, letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 10),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  getObservableState() {
    return [openTab];
  }
}

final openTab = ObservableState(0);
