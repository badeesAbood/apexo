import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/dashboard/page_dashboard.dart';
import 'package:apexo/pages/expenses/page_expenses.dart';
import 'package:apexo/pages/labwork/page_labwork.dart';
import 'package:apexo/pages/patients/page_patients.dart';
import 'package:apexo/pages/stats/page_stats.dart';
import 'package:apexo/state/admins.dart';
import 'package:apexo/state/backups.dart';
import 'package:apexo/state/charts.dart';
import 'package:apexo/state/permissions.dart';
import 'package:apexo/state/state.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/expenses/expenses_model.dart';
import 'package:apexo/state/stores/expenses/expenses_store.dart';
import 'package:apexo/state/stores/labworks/labwork_model.dart';
import 'package:apexo/state/stores/labworks/labworks_store.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/doctors/doctor_model.dart';
import 'package:apexo/state/stores/doctors/doctors_store.dart';
import 'package:apexo/state/users.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import '../i18/index.dart';
import 'calendar/page_calendar.dart';
import 'doctors/page_doctors.dart';
import 'settings/page_settings.dart';
import '../backend/observable/observable.dart';
import "../state/stores/appointments/appointments_store.dart";
import "../state/stores/settings/settings_store.dart";

class Page {
  IconData icon;
  String title;
  String identifier;
  ObservingWidget Function() body;

  /// show in the navigation pane and thus being activated
  bool accessible;

  /// show in the footer of the navigation pane
  bool onFooter;

  /// callback to be called when the page is selected
  void Function()? onSelect;

  Page({
    required this.title,
    required this.identifier,
    required this.icon,
    required this.body,
    this.accessible = true,
    this.onFooter = false,
    this.onSelect,
  });
}

class Pages extends ObservableObject {
  List<Page> genAllPages() => [
        Page(
          title: txt("dashboard"),
          identifier: "dashboard",
          icon: FluentIcons.home,
          body: PageDashboard.new,
          accessible: true,
          onSelect: () {
            chartsState.resetSelected();
            patients.synchronize();
            appointments.synchronize();
          },
        ),
        Page(
          title: txt("doctors"),
          identifier: "doctors",
          icon: FluentIcons.medical,
          body: DoctorsPage.new,
          accessible: permissions.list[0] || state.isAdmin,
          onSelect: () {
            doctors.synchronize();
          },
        ),
        Page(
          title: txt("patients"),
          identifier: "patients",
          icon: FluentIcons.medication_admin,
          body: PatientPage.new,
          accessible: permissions.list[1] || state.isAdmin,
          onSelect: () {
            patients.synchronize();
          },
        ),
        Page(
          title: txt("appointments"),
          identifier: "calendar",
          icon: FluentIcons.calendar,
          body: Calendar.new,
          accessible: permissions.list[2] || state.isAdmin,
          onSelect: () {
            appointments.synchronize();
          },
        ),
        Page(
          title: txt("labworks"),
          identifier: "labworks",
          icon: FluentIcons.manufacturing,
          body: LabworksPage.new,
          accessible: permissions.list[3] || state.isAdmin,
          onSelect: () {
            labworks.synchronize();
          },
        ),
        Page(
          title: txt("expenses"),
          identifier: "expenses",
          icon: FluentIcons.receipt_processing,
          body: ExpensesPage.new,
          accessible: permissions.list[4] || state.isAdmin,
          onSelect: () {
            expenses.synchronize();
          },
        ),
        Page(
          title: txt("statistics"),
          identifier: "statistics",
          icon: FluentIcons.chart,
          body: PageStats.new,
          accessible: permissions.list[5] || state.isAdmin,
          onSelect: () {
            chartsState.resetSelected();
            patients.synchronize();
            appointments.synchronize();
          },
        ),
        Page(
          title: txt("settings"),
          identifier: "settings",
          icon: FluentIcons.settings,
          body: SettingsPage.new,
          accessible: true,
          onFooter: false,
          onSelect: () {
            globalSettings.synchronize();
            admins.reloadFromRemote();
            backups.reloadFromRemote();
            permissions.reloadFromRemote();
            users.reloadFromRemote();
          },
        ),
      ];

  late List<Page> allPages = genAllPages();

  int currentPageIndex = 0;
  List<int> history = [];

  // bottom sheets
  Patient openPatient = Patient.fromJson({});
  Appointment openAppointment = Appointment.fromJson({});
  Doctor openMember = Doctor.fromJson({});
  Labwork openLabwork = Labwork.fromJson({});
  Expense openExpense = Expense.fromJson({});

  int selectedTabInSheet = 0;

  Page get currentPage {
    return allPages[currentPageIndex];
  }

  goBack() {
    if (history.isNotEmpty) {
      currentPageIndex = history.removeLast();
      if (currentPage.onSelect != null) {
        currentPage.onSelect!();
      }
    }
    notify();
  }

  navigate(Page page) {
    if (currentPageIndex == allPages.indexOf(page)) return;
    history.add(currentPageIndex);
    currentPageIndex = allPages.indexOf(page);
    if (currentPage.onSelect != null) {
      currentPage.onSelect!();
    }
    notify();
  }

  Page? getByIdentifier(String identifier) {
    var target = allPages.where((element) => element.identifier == identifier);
    if (target.isEmpty) return null;
    return target.first;
  }
}

final Pages pages = Pages();
