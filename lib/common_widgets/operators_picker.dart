import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/doctors/open_doctor_panel.dart';
import 'package:apexo/common_widgets/tag_input.dart';
import 'package:apexo/features/doctors/doctor_model.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';

class OperatorsPicker extends StatelessWidget {
  final List<String> value;
  final void Function(List<String>) onChanged;
  const OperatorsPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TagInputWidget(
      key: WK.fieldOperators,
      suggestions: doctors.present.values.map((doctor) => TagInputItem(value: doctor.id, label: doctor.title)).toList(),
      onChanged: (s) {
        onChanged(s.where((x) => x.value != null).map((x) => x.value!).toList());
      },
      initialValue: value.map((id) => TagInputItem(value: id, label: doctors.get(id)!.title)).toList(),
      onItemTap: (tag) {
        Doctor? tapped = doctors.get(tag.value ?? "");
        openDoctor(tapped);
      },
      strict: true,
      limit: 999,
      placeholder: txt("selectDoctors"),
    );
  }
}
