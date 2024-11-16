import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';

import '../../../pages/shared/week_calendar.dart';

class Appointment extends AgendaItem {
  @override
  String? get avatar {
    if (imgs.isEmpty) return null;
    return imgs.first;
  }

  @override
  String get title {
    if (patient == null) {
      return "  ";
    } else {
      return patient!.title;
    }
  }

  Patient? get patient {
    return patients.get(patientID ?? "return null when null");
  }

  List<Member> get operators {
    List<Member> foundOperators = [];
    for (var id in operatorsIDs) {
      var found = staff.get(id);
      if (found != null) {
        foundOperators.add(found);
      }
    }
    return foundOperators;
  }

  Set<int> get availableWeekDays {
    return operators.expand((element) => element.dutyDays).toSet().map((day) => allDays.indexOf(day) + 1).toSet();
  }

  @override
  String get subtitleLine1 {
    return "${isDone() ? "✔️ " : ""}${isDone() && postOpNotes.isNotEmpty ? postOpNotes : preOpNotes}";
  }

  @override
  String get subtitleLine2 {
    if (operatorsIDs.isEmpty) return "";
    return "👨‍⚕️ ${operatorsIDs.map((id) => staff.get(id)?.title).join(", ")}";
  }

  bool get fullPaid {
    return paid == price;
  }

  bool get overPaid {
    return paid > price;
  }

  bool get underPaid {
    return paid < price;
  }

  bool get isMissed {
    return date().isBefore(DateTime.now()) && date().difference(DateTime.now()).inDays.abs() > 0 && !isDone();
  }

  bool get firstAppointmentForThisPatient {
    if (patient == null) return false;
    return patient!.allAppointments.first == this;
  }

  // id: id of the member (inherited from Model)
  // date: date (& time) of the member (inherited from AgendaItem)
  /* 1 */ List<String> operatorsIDs = [];
  /* 2 */ String? patientID;
  /* 3 */ String preOpNotes = "";
  /* 4 */ String postOpNotes = "";
  /* 5 */ List<String> prescriptions = [];
  /* 6 */ double price = 0;
  /* 7 */ double paid = 0;
  /* 8 */ List<String> imgs = [];

  Appointment.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    /* 1 */ operatorsIDs = List<String>.from(json["operatorsIDs"] ?? operatorsIDs);
    /* 2 */ prescriptions = List<String>.from(json["prescriptions"] ?? prescriptions);
    /* 3 */ patientID = json["patientID"] ?? patientID;
    /* 4 */ preOpNotes = json["preOpNotes"] ?? preOpNotes;
    /* 5 */ postOpNotes = json["postOpNotes"] ?? postOpNotes;
    /* 6 */ price = double.parse((json["price"] ?? price).toString());
    /* 7 */ paid = double.parse((json["paid"] ?? paid).toString());
    /* 8 */ imgs = List<String>.from(json["imgs"] ?? imgs);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Appointment.fromJson({});
    /* 1 */ if (operatorsIDs.isNotEmpty) json['operatorsIDs'] = operatorsIDs;
    /* 2 */ if (prescriptions.isNotEmpty) json['prescriptions'] = prescriptions;
    /* 3 */ if (patientID != d.patientID) json['patientID'] = patientID;
    /* 4 */ if (preOpNotes != d.preOpNotes) json['preOpNotes'] = preOpNotes;
    /* 5 */ if (postOpNotes != d.postOpNotes) json['postOpNotes'] = postOpNotes;
    /* 6 */ if (price != d.price) json['price'] = price;
    /* 7 */ if (paid != d.paid) json['paid'] = paid;
    /* 8 */ if (imgs.isNotEmpty) json['imgs'] = imgs;

    json.remove("title"); // remove since it is a computed value in this case

    return json;
  }
}
