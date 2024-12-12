import 'package:apexo/backend/observable/model.dart';
import 'package:apexo/state/state.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:table_calendar/table_calendar.dart';

final allDays = StartingDayOfWeek.values.map((e) => e.name).toList();

class Doctor extends Model {
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

  @override
  bool get locked {
    if (lockToUserIDs.isEmpty) return false;
    if (state.isAdmin) return false;
    return !lockToUserIDs.contains(state.currentUserID);
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
  // TODO: lockToUserIDs editing GUI, should only available to admins while online

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
