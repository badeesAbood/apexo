import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/page_dashboard.dart';
import 'package:apexo/pages/page_labwork.dart';
import 'package:apexo/pages/page_patients.dart';
import 'package:apexo/pages/page_stats.dart';
import 'package:apexo/state/charts.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/labworks/labwork_model.dart';
import 'package:apexo/state/stores/labworks/labworks_store.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import '../i18/index.dart';
import '../pages/page_calendar.dart';
import '../pages/page_staff.dart';
import '../pages/page_settings.dart';
import '../backend/observable/observable.dart';
import "../state/stores/appointments/appointments_store.dart";
import "../state/stores/settings/settings_store.dart";

class Page {
  IconData icon;
  String title;
  String identifier;
  ObservingWidget Function() body;

  /// show in the navigation pane and thus being activated
  bool show;

  /// presence of a dominant page means that no other page can be shown
  bool dominant;

  /// show in the footer of the navigation pane
  bool onFooter;

  /// callback to be called when the page is selected
  void Function()? onSelect;

  Page({
    required this.title,
    required this.identifier,
    required this.icon,
    required this.body,
    this.show = true,
    this.dominant = false,
    this.onFooter = false,
    this.onSelect,
  });
}

class Pages extends ObservableObject {
  final List<Page> allPages = [
    Page(
      title: "Dashboard",
      identifier: "dashboard",
      icon: FluentIcons.home,
      body: PageDashboard.new,
      show: true,
      dominant: false,
      onSelect: () {
        chartsState.resetSelected();
        patients.synchronize();
        appointments.synchronize();
      },
    ),
    Page(
      title: "Staff",
      identifier: "staff",
      icon: FluentIcons.medical,
      body: StaffMembers.new,
      show: true,
      dominant: false,
      onSelect: () {
        staff.synchronize();
      },
    ),
    Page(
      title: "Patients",
      identifier: "patients",
      icon: FluentIcons.medication_admin,
      body: PatientPage.new,
      show: true,
      dominant: false,
      onSelect: () {
        patients.synchronize();
      },
    ),
    Page(
      title: "Appointments calendar",
      identifier: "calendar",
      icon: FluentIcons.calendar,
      body: Calendar.new,
      show: true,
      onSelect: () {
        appointments.synchronize();
      },
    ),
    Page(
      title: "Labworks",
      identifier: "labworks",
      icon: FluentIcons.manufacturing,
      body: LabworksPage.new,
      show: true,
      onSelect: () {
        labworks.synchronize();
      },
    ),
    Page(
      title: "Statistics",
      identifier: "statistics",
      icon: FluentIcons.chart,
      body: PageStats.new,
      show: true,
      dominant: false,
      onSelect: () {
        chartsState.resetSelected();
        patients.synchronize();
        appointments.synchronize();
      },
    ),
    Page(
      title: locale.s.settings,
      identifier: "settings",
      icon: FluentIcons.view,
      body: PageTwo.new,
      show: true,
      dominant: false,
      onFooter: true,
      onSelect: () {
        globalSettings.synchronize();
      },
    ),
  ];

  int currentPageIndex = 0;
  List<int> history = [];

  // bottom sheets
  Patient openPatient = Patient.fromJson({});
  Appointment openAppointment = Appointment.fromJson({});
  Member openMember = Member.fromJson({});
  Labwork openLabwork = Labwork.fromJson({});

  int selectedTabInSheet = 0;

  Page get currentPage {
    return activePages[currentPageIndex];
  }

  List<Page> get activePages {
    var shownPages = allPages.where((page) {
      return page.show;
    });
    var dominantOnly = shownPages.where((page) => page.dominant);
    if (dominantOnly.isNotEmpty) {
      return dominantOnly.toList();
    }
    return shownPages.toList();
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
    if (currentPageIndex == activePages.indexOf(page)) return;
    history.add(currentPageIndex);
    currentPageIndex = activePages.indexOf(page);
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
