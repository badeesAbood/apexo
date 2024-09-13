import '../../../pages/widgets/week_calendar.dart';

class Appointment extends AgendaItem {
  String operatingDoctor = "";

  @override
  String get subtitle {
    return operatingDoctor;
  }

  Appointment.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    operatingDoctor = json["operatingDoctor"] ?? operatingDoctor;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Appointment.fromJson({});
    if (operatingDoctor != d.operatingDoctor) json['operatingDoctor'] = operatingDoctor;
    return json;
  }
}
