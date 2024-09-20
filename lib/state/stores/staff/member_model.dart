import 'package:apexo/backend/observable/model.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:table_calendar/table_calendar.dart';

final allDays = StartingDayOfWeek.values.map((e) => e.name).toList();

class Member extends Model {
  List<Appointment> get allAppointments {
    return appointments.present.where((x) => x.operatorsIDs.contains(id)).toList();
  }

  List<Appointment> get upcomingAppointments {
    return allAppointments.where((x) => x.date().isAfter(DateTime.now())).toList();
  }

  List<Appointment> get pastDoneAppointments {
    return allAppointments.where((x) => x.date().isBefore(DateTime.now()) && x.isDone()).toList();
  }

  Map<String, String>? _labels;
  @override
  Map<String, String> get labels {
    return _labels ??= {
      "Operates": operates ? "Yes" : "No",
      "Upcoming appointments": upcomingAppointments.length.toString(),
      "Past appointments": pastDoneAppointments.length.toString()
    };
  }

  // id: id of the member (inherited from Model)
  // title: name of the member (inherited from Model)
  /* 1 */ bool operates = false;
  /* 2 */ List<String> canView = [];
  /* 3 */ List<String> canEdit = [];
  /* 4 */ List<String> dutyDays = allDays;
  @override
  Member.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    /* 1 */ operates = json['operates'] ?? operates;
    /* 2 */ canView = List<String>.from(json['canView'] ?? canView);
    /* 3 */ canEdit = List<String>.from(json['canEdit'] ?? canEdit);
    /* 4 */ dutyDays = List<String>.from(json['dutyDays'] ?? dutyDays);
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Member.fromJson({});
    /* 1 */ if (operates != d.operates) json['operates'] = operates;
    /* 2 */ if (canView.toString() != d.canView.toString()) json['canView'] = canView;
    /* 3 */ if (canEdit.toString() != d.canEdit.toString()) json['canEdit'] = canEdit;
    /* 4 */ if (dutyDays.toString() != d.dutyDays.toString()) json['dutyDays'] = dutyDays;

    return json;
  }
}
