import 'package:apexo/backend/observable/model.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:intl/intl.dart';

class Labwork extends Model {
  @override
  get labels {
    return {
      "Laboratory": lab,
      "Month": DateFormat("MMM yyyy", locale.s.$code).format(date),
      "Patient": patient?.title ?? "Unknown",
      "Paid": paid ? txt("paid") : txt("unpaid"),
      "doctors": operators.map((e) => e.title).join(", "),
    };
  }

  Patient? get patient {
    return patients.get(patientID ?? "");
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

  // id: id of the labwork (inherited from Model)
  // title: title of the labwork (inherited from Model)
  /* 1 */ List<String> operatorsIDs = [];
  /* 2 */ String? patientID;
  /* 3 */ String note = "";
  /* 4 */ bool paid = false;
  /* 5 */ double price = 0;
  /* 6 */ DateTime date = DateTime.now();
  /* 7 */ String lab = "";
  /* 8 */ String phoneNumber = "";

  Labwork.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    /* 1 */ operatorsIDs = List<String>.from(json["operatorsIDs"] ?? operatorsIDs);
    /* 2 */ patientID = json["patientID"] ?? patientID;
    /* 3 */ note = json["note"] ?? note;
    /* 4 */ price = json["price"] ?? price;
    /* 5 */ paid = json["paid"] ?? paid;
    /* 6 */ date = json["date"] != null ? DateTime.fromMillisecondsSinceEpoch(json["date"]) : date;
    /* 7 */ lab = json["lab"] ?? lab;
    /* 8 */ phoneNumber = json["phoneNumber"] ?? phoneNumber;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Labwork.fromJson({});
    /* 1 */ if (operatorsIDs.isNotEmpty) json['operatorsIDs'] = operatorsIDs;
    /* 2 */ if (patientID != d.patientID) json['patientID'] = patientID;
    /* 3 */ if (note != d.note) json['note'] = note;
    /* 4 */ if (price != d.price) json['price'] = price;
    /* 5 */ if (paid != d.paid) json['paid'] = paid;
    /* 6 */ if (date != d.date) json['date'] = date.millisecondsSinceEpoch;
    /* 7 */ if (lab != d.lab) json['lab'] = lab;
    /* 8 */ if (phoneNumber != d.phoneNumber) json['phoneNumber'] = phoneNumber;
    return json;
  }
}
