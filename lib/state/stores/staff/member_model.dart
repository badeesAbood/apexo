import 'package:apexo/backend/observable/model.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:table_calendar/table_calendar.dart';

final allDays = StartingDayOfWeek.values.map((e) => e.name).toList();

class Member extends Model {
  List<Appointment> get allAppointments {
    return appointments.present.values.where((x) => x.operatorsIDs.contains(id)).toList();
  }

  List<Appointment> get upcomingAppointments {
    return allAppointments.where((x) => x.date().isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.date().compareTo(b.date()));
  }

  List<Appointment> get pastDoneAppointments {
    return allAppointments.where((x) => x.date().isBefore(DateTime.now()) && x.isDone()).toList();
  }

  Map<String, String>? _labels;
  @override
  Map<String, String> get labels {
    return _labels ??= {
      "Upcoming appointments": upcomingAppointments.length.toString(),
      "Past appointments": pastDoneAppointments.length.toString()
    };
  }

  // id: id of the member (inherited from Model)
  // title: name of the member (inherited from Model)
  /* 1 */ List<String> dutyDays = allDays;
  /* 2 */ String email = "";

  @override
  Member.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    /* 1 */ dutyDays = List<String>.from(json['dutyDays'] ?? dutyDays);
    /* 2 */ email = json["email"] ?? email;
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Member.fromJson({});
    /* 1 */ if (dutyDays.toString() != d.dutyDays.toString()) json['dutyDays'] = dutyDays;
    /* 2 */ if (email != d.email) json["email"] = email;
    return json;
  }
}
