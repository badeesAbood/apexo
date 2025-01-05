import 'dart:math';

import 'package:apexo/features/appointments/appointment_model.dart';
import 'package:apexo/features/doctors/doctor_model.dart';
import 'package:apexo/features/expenses/expense_model.dart';
import 'package:apexo/features/labwork/labwork_model.dart';
import 'package:apexo/features/patients/patient_model.dart';

const _firstNames = [
  "John",
  "Jane",
  "Bob",
  "Alice",
  "Mike",
  "Emily",
  "David",
  "Sarah",
  "Tom",
  "Lisa",
  "Chris",
  "Karen",
  "Mark",
  "Laura",
  "Kevin",
  "Olivia",
  "Steve",
  "Rachel",
  "Paul",
  "Amanda",
  "Eric",
  "Jessica",
  "Brian",
  "Megan",
  "Ryan",
  "Stephanie",
  "Jeff",
  "Nicole",
  "Scott",
  "Melissa",
  "Greg",
  "Lauren",
  "Matt",
  "Hannah",
  "Peter",
  "Ashley",
  "Tim",
  "Katherine",
  "Josh",
  "Christine",
  "Andrew",
  "Natalie",
  "Ray",
  "Amber",
  "Kevin",
  "Rachel",
  "Chris",
  "Megan",
  "Brian",
  "Stephanie",
  "Jeff",
  "Nicole",
  "Scott",
  "Melissa",
  "Greg",
  "Lauren",
  "Matt",
  "Hannah",
  "Peter",
  "Ashley",
  "Tim",
  "Katherine",
  "Josh",
];

const _lastNames = [
  "Smith",
  "Johnson",
  "Williams",
  "Jones",
  "Brown",
  "Davis",
  "Miller",
  "Wilson",
  "Moore",
  "Taylor",
  "Anderson",
  "Thomas",
  "Jackson",
  "White",
  "Harris",
  "Martin",
  "Thompson",
  "Garcia",
  "Martinez",
  "Robinson",
  "Clark",
  "Rodriguez",
  "Lewis",
  "Lee",
  "Walker",
  "Hall",
  "Allen",
  "Young",
  "Hernandez",
  "King",
  "Wright",
  "Lopez",
  "Hill",
  "Scott",
  "Green",
  "Adams",
  "Baker",
  "Gonzalez",
  "Nelson",
  "Carter",
  "Mitchell",
  "Perez",
  "Roberts",
  "Turner",
  "Phillips",
  "Campbell",
];

const _patientTags = [
  "Diabetic",
  "Hypertensive",
  "Asthmatic",
  "Heart Patient",
  "Conservative",
  "Smoker",
];

const _preOpNotes = [
  "routine dental checkup.",
  "root canal treatment.",
  "dental implant placement.",
  "dental bridge placement.",
  "dental cleaning.",
  "dental filling.",
  "dental crown placement.",
  "dental extraction.",
  "dental veneer placement.",
  "dental whitening.",
  "dental bonding.",
  "dental inlay placement.",
  "dental onlay placement.",
  "dental veneer removal.",
  "dental bonding removal.",
  "dental inlay removal.",
  "dental onlay removal.",
  "dental whitening removal.",
  "dental brackets removal.",
  "dental brackets placement.",
  "wisdom tooth removal.",
];

const _postOpNotes = [
  "Done with no complications.",
  "Bleeding stopped.",
  "No complications.",
  "Prescription given.",
  "Next appointment scheduled.",
  "Follow-up required",
  "Fractured tooth.",
  "Fractured instrument",
  "Infection",
  "Nerve damage.",
  "Pain management is required.",
  "Given prescription for pain management.",
  "Prescription for antibiotics.",
  "Full recovery expected.",
  "Patient is recovering well.",
  "Patient is recovering slowly.",
  "Slow healing process.",
  "Oral hygiene instructions given.",
  "Patient is not responding well.",
  "Patient is in pain.",
  "Patient is not comfortable.",
  "Patient is not happy with the result.",
  "Patient is not satisfied with the result.",
  "Over the counter medication given.",
  "Over instrumentation was done.",
  "Can not be done.",
  "Expectation of the patient can not be met.",
  "Reassurance given.",
];

const Map<String, String> _labs = {
  "Master Design Lab": "07518076345",
  "Everest Dental Lab": "07538971145",
  "Galaxy Orthodontics Lab": "07576298412",
  "Royal Dental Lab": "07517409134",
  "Acer Veneers Lab": "07537601928",
};

const Map<String, String> _receiptIssuers = {
  "Echo Dental Supplies": "075389000145",
  "Dental Supplies Ltd": "075188176345",
  "Vana Office Furniture": "07517402134",
  "Dental Equipment Ltd": "07577798412",
  "COX-O Dental Supplies": "07537601228",
  "Village Stationary": "07517409134",
};

const List<String> _labworkNotes = [
  "Zirconia Crown",
  "Ceramic Crown",
  "Lithium Disilicate Crown",
  "Resin Crown",
  "Onlay",
  "Inlay",
  "Inlay and Onlay",
  "Dental Veneer",
  "Dental Veneer and Crown",
  "Hyrax",
  "Expander",
  "Retainer",
  "Invisalign",
  "Invisalign Teen",
  "Invisalign Express",
  "Invisalign Lite",
  "Aligners",
  "Quad-Helix",
];

const List<String> _receiptItems = [
  "Paper",
  "Ink",
  "Toner",
  "Toner Cartridge",
  "Pens",
  "Stapler",
  "Mosquito",
  "Bond",
  "Composite",
  "Braces",
  "Screw",
  "Dental Implant",
  "Strip",
  "Forceps",
  "Gutta Percha",
  "Gutta Percha Rod",
  "X-ray Film",
  "X-ray Film Holder",
  "Alcohol",
  "Cotton",
  "Gauze",
  "Gauze Roll",
  "Gauze Pad",
  "Sterilizer",
  "Sterilizer Bag",
  "Sterilizer Tray",
  "Surgical Instruments",
  "Chlorhexidine",
  "Chlorhexidine Gauze",
  "Solvent",
  "3D Printing Resin",
  "FEP Film",
  "Water",
  "Rubber Dam",
  "Celluloid Strip",
  "Posterior Composite",
  "Dental Cement",
  "Dental Adhesive",
  "Dental Adhesive Remover",
  "Burs",
  "Dental Drill",
];

const List<String> _receiptTags = [
  "Urgent",
  "Regular",
  "Installment",
  "Online Purchase",
  "Debit",
  "Credit",
];

String _generateName() {
  final random = Random();
  final firstName = _firstNames[random.nextInt(_firstNames.length)];
  final lastName = _lastNames[random.nextInt(_lastNames.length)];
  return "$firstName $lastName";
}

String _demoEmailToName(String name) {
  return "${name.split(" ").first.toLowerCase()}@apexo.app";
}

String _randomAddress() {
  final random = Random();
  return "${random.nextInt(1000)} ${_lastNames[random.nextInt(_lastNames.length)]} St";
}

List<Doctor> _savedDoctors = [];
List<Patient> _savedPatients = [];

Doctor _demoDoctor() {
  final name = _generateName();
  return Doctor.fromJson({
    "title": "Dr. $name",
    "email": _demoEmailToName(name),
  });
}

Patient _demoPatient() {
  final name = _generateName();
  return Patient.fromJson({
    "title": name,
    "gender": Random().nextInt(5).isEven ? 0 : 1,
    "phone": "+1 555-555-5555",
    "address": _randomAddress(),
    "birth": DateTime.now().year - 5 - Random().nextInt(55),
    "tags":
        List.generate(Random().nextInt(5).isEven ? 0 : 1, (_) => _patientTags[Random().nextInt(_patientTags.length)]),
  });
}

Appointment _demoAppointment() {
  final doctor = _savedDoctors[Random().nextInt(_savedDoctors.length)];
  final patient = _savedPatients[Random().nextInt(_savedPatients.length)];
  final price = Random().nextInt(1000);
  final date = DateTime.now()
      .add(Duration(hours: Random().nextInt(24 * 30)))
      .subtract(Duration(hours: Random().nextInt(24 * 200)));
  final future = date.isAfter(DateTime.now());
  return Appointment.fromJson({
    "date": date.millisecondsSinceEpoch / 60000,
    "isDone": future
        ? false
        : Random().nextInt(10) == 5
            ? false
            : true,
    "operatorsIDs": [doctor.id],
    "patientID": patient.id,
    "preOpNotes": _preOpNotes[Random().nextInt(_preOpNotes.length)],
    "postOpNotes": future ? "" : _postOpNotes[Random().nextInt(_postOpNotes.length)],
    "price": price,
    "paid": future
        ? null
        : Random().nextInt(20) == 15
            ? Random().nextInt(1500)
            : price,
  });
}

Labwork _demoLabwork() {
  final patient = _savedPatients[Random().nextInt(_savedPatients.length)];
  final date = DateTime.now()
      .add(Duration(hours: Random().nextInt(24 * 30)))
      .subtract(Duration(hours: Random().nextInt(24 * 200)));
  final future = date.isAfter(DateTime.now());
  final lab = _labs.keys.toList()[Random().nextInt(_labs.length)];
  return Labwork.fromJson({
    "date": (date.millisecondsSinceEpoch / (60 * 60 * 1000)).toInt(),
    "operatorsIDs": [_savedDoctors[Random().nextInt(_savedDoctors.length)].id],
    "patientID": patient.id,
    "paid": future ? null : true,
    "price": Random().nextInt(100),
    "lab": lab,
    "phoneNumber": _labs[lab],
    "note": _labworkNotes[Random().nextInt(_labworkNotes.length)],
  });
}

Expense _demoExpense() {
  final date = DateTime.now()
      .add(Duration(hours: Random().nextInt(24 * 30)))
      .subtract(Duration(hours: Random().nextInt(24 * 200)));
  final future = date.isAfter(DateTime.now());
  final price = Random().nextInt(700);
  final receiptIssuer = _receiptIssuers.keys.toList()[Random().nextInt(_receiptIssuers.length)];
  return Expense.fromJson({
    "date": (date.millisecondsSinceEpoch / (60 * 60 * 1000)).toInt(),
    "paid": future ? null : true,
    "amount": price,
    "issuer": receiptIssuer,
    "phoneNumber": _receiptIssuers[receiptIssuer],
    "items": List.generate(Random().nextInt(5).isEven ? 0 : Random().nextInt(5),
        (_) => _receiptItems[Random().nextInt(_receiptItems.length)]),
    "tags": List.generate(Random().nextInt(5).isEven ? 0 : Random().nextInt(2),
        (_) => _receiptTags[Random().nextInt(_receiptTags.length)]),
  });
}

List<Doctor> demoDoctors(int length) {
  _savedDoctors = List.generate(length, (_) => _demoDoctor());
  return _savedDoctors;
}

List<Patient> demoPatients(int length) {
  _savedPatients = List.generate(length, (_) => _demoPatient());
  return _savedPatients;
}

List<Appointment> demoAppointments(int length) {
  return List.generate(length, (_) => _demoAppointment());
}

List<Labwork> demoLabworks(int length) {
  return List.generate(length, (_) => _demoLabwork());
}

List<Expense> demoExpenses(int length) {
  return List.generate(length, (_) => _demoExpense());
}
