import 'package:apexo/pages/patients/modal_patient.dart';
import 'package:apexo/pages/shared/tag_input.dart';
import 'package:apexo/state/stores/patients/patient_model.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:fluent_ui/fluent_ui.dart';

class PatientPicker extends StatelessWidget {
  final void Function(String? id) onChanged;
  final String? value;
  const PatientPicker({super.key, required this.onChanged, required this.value});

  @override
  Widget build(BuildContext context) {
    return TagInputWidget(
      key: super.key,
      onItemTap: (tag) {
        Patient? tapped = patients.get(tag.value ?? "");
        Map<String, dynamic> json = tapped != null ? tapped.toJson() : {};
        openSinglePatient(
          context: context,
          json: json,
          title: "Patient Details",
          onSave: patients.set,
          editing: true,
        );
      },
      suggestions: patients.present.values.map((e) => TagInputItem(value: e.id, label: e.title)).toList(),
      onChanged: (s) {
        if (s.isEmpty) return onChanged(null);
        onChanged(s.first.value ?? "");
      },
      initialValue: value != null ? [TagInputItem(value: value!, label: patients.get(value!)!.title)] : [],
      strict: true,
      limit: 1,
      placeholder: "Select patient",
    );
  }
}
