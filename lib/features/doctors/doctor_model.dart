import 'package:apexo/core/model.dart';
import 'package:apexo/services/archived.dart';
import 'package:apexo/services/login.dart';
import 'package:apexo/features/appointments/appointment_model.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:table_calendar/table_calendar.dart';

final allDays = StartingDayOfWeek.values.map((e) => e.name).toList();

class Doctor extends Model {
  List<Appointment> get allAppointments {
    return (appointments.byDoctor[id]?["all"] ?? [])
        .where((appointment) => appointment.archived != true || showArchived())
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Appointment> get upcomingAppointments {
    return (appointments.byDoctor[id]?["upcoming"] ?? [])
        .where((appointment) => appointment.archived != true || showArchived())
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Appointment> get pastDoneAppointments {
    return (appointments.byDoctor[id]?["past"] ?? [])
        .where((appointment) => appointment.archived != true || showArchived())
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  bool get locked {
    if (lockToUserIDs.isEmpty) return false;
    if (login.isAdmin) return false;
    return !lockToUserIDs.contains(login.currentUserID);
  }

  Map<String, String>? _labels;
  @override
  Map<String, String> get labels {
    return _labels ??= {
      "upcomingAppointments": upcomingAppointments.length.toString(),
      "pastAppointments": pastDoneAppointments.length.toString()
    };
  }

  // id: id of the member (inherited from Model)
  // title: name of the member (inherited from Model)
  /* 1 */ List<String> dutyDays = allDays;
  /* 2 */ String email = "";
  /* 3 */ List<String> lockToUserIDs = [];

  @override
  Doctor.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    /* 1 */ dutyDays = List<String>.from(json['dutyDays'] ?? dutyDays);
    /* 2 */ email = json["email"] ?? email;
    /* 3 */ lockToUserIDs = List<String>.from(json['lockToUserIDs'] ?? lockToUserIDs);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Doctor.fromJson({});
    /* 1 */ if (dutyDays.toString() != d.dutyDays.toString()) json['dutyDays'] = dutyDays;
    /* 2 */ if (email != d.email) json["email"] = email;
    /* 3 */ if (lockToUserIDs.toString() != d.lockToUserIDs.toString()) json["lockToUserIDs"] = lockToUserIDs;
    return json;
  }
}
