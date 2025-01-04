import 'package:apexo/core/observable.dart';
import 'package:apexo/features/appointments/appointment_model.dart';
import 'package:apexo/features/appointments/appointments_store.dart';

class _DashboardController {
  _DashboardController() {
    appointments.observableMap.observe((e) {
      // nullify the cache
      _thisMonthAppointments = null;
      _todayAppointments = null;
    });
  }

  final currentOpenTab = ObservableState(0);

  List<Appointment>? _thisMonthAppointments;
  List<Appointment> get thisMonthAppointments {
    if (_thisMonthAppointments != null) {
      return _thisMonthAppointments!;
    }
    final DateTime now = DateTime.now();
    List<Appointment> res = [];
    for (var appointment in appointments.present.values) {
      if (appointment.date.year != now.year) continue;
      if (appointment.date.month != now.month) continue;
      res.add(appointment);
    }
    return res..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Appointment>? _todayAppointments;
  List<Appointment> get todayAppointments {
    if (_todayAppointments != null) {
      return _todayAppointments!;
    }
    final DateTime now = DateTime.now();
    List<Appointment> res = [];
    for (var appointment in thisMonthAppointments) {
      if (appointment.date.day != now.day) continue;
      res.add(appointment);
    }
    _todayAppointments = res..sort((a, b) => a.date.compareTo(b.date));
    return _todayAppointments!;
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
}

final dashboardCtrl = _DashboardController();
