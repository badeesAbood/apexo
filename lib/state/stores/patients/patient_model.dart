import 'package:apexo/backend/observable/model.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';

class Patient extends Model {
  List<Appointment> get allAppointments {
    return appointments.present.where((x) => x.patientID == id).toList()..sort((a, b) => a.date().compareTo(b.date()));
  }

  List<Appointment> get doneAppointments {
    return allAppointments.where((x) => x.isDone()).toList();
  }

  List<Appointment> get upcomingAppointments {
    return allAppointments.where((x) => x.date().isAfter(DateTime.now())).toList();
  }

  List<Appointment> get pastAppointments {
    return allAppointments.where((x) => x.date().isBefore(DateTime.now())).toList();
  }

  int get age {
    return DateTime.now().year - birth;
  }

  double get paymentsMade {
    return doneAppointments.fold(0.0, (value, element) => value + element.paid);
  }

  double get pricesGiven {
    return doneAppointments.fold(0.0, (value, element) => value + element.price);
  }

  bool get overPaid {
    return paymentsMade > pricesGiven;
  }

  bool get fullPaid {
    return paymentsMade == pricesGiven;
  }

  bool get underPaid {
    return paymentsMade < pricesGiven;
  }

  double get outstandingPayments {
    return pricesGiven - paymentsMade;
  }

  int? get daysSinceLastAppointment {
    if (doneAppointments.isEmpty) return null;
    return DateTime.now().difference(doneAppointments.last.date()).inDays;
  }

  @override
  Map<String, String> get labels {
    Map<String, String> buildingLabels = {
      "Age": (DateTime.now().year - birth).toString(),
    };

    if (daysSinceLastAppointment == null) {
      buildingLabels["Last visit"] = "No visits";
    } else {
      buildingLabels["Last visit"] = "$daysSinceLastAppointment days ago";
    }

    if (gender == 0) {
      buildingLabels["Gender"] = "♀";
    } else {
      buildingLabels["Gender"] = "♂️";
    }

    if (outstandingPayments > 0) {
      buildingLabels["Pay"] = "Underpaid🔻";
    }

    if (outstandingPayments < 0) {
      buildingLabels["Pay"] = "Overpaid🔺";
    }

    if (paymentsMade != 0) {
      buildingLabels["Total payments"] = "$paymentsMade";
    }

    for (var i = 0; i < tags.length; i++) {
      buildingLabels[List.generate(i, (_) => "\u200B").join("")] = tags[i];
    }
    return buildingLabels;
  }

  // id: id of the patient (inherited from Model)
  // title: name of the patient (inherited from Model)
  /* 1 */ int birth = DateTime.now().year - 18;
  /* 2 */ int gender = 0; // 0 for female, 1 for male
  /* 3 */ String phone = "";
  /* 4 */ String email = "";
  /* 5 */ String address = "";
  /* 6 */ List<String> tags = [];
  /* 7 */ String notes = "";

  @override
  Patient.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    /* 1 */ birth = json['birth'] ?? birth;
    /* 2 */ gender = json['gender'] ?? gender;
    /* 3 */ phone = json['phone'] ?? phone;
    /* 4 */ email = json['email'] ?? email;
    /* 5 */ address = json['address'] ?? address;
    /* 6 */ tags = List<String>.from(json['tags'] ?? tags);
    /* 7 */ notes = json['notes'] ?? notes;
  }
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Patient.fromJson({});

    /* 1 */ if (birth != d.birth) json['birth'] = birth;
    /* 2 */ if (gender != d.gender) json['gender'] = gender;
    /* 3 */ if (phone != d.phone) json['phone'] = phone;
    /* 4 */ if (email != d.email) json['email'] = email;
    /* 5 */ if (address != d.address) json['address'] = address;
    /* 6 */ if (tags.toString() != d.tags.toString()) json['tags'] = tags;
    /* 7 */ if (notes != d.notes) json['notes'] = notes;
    return json;
  }
}
