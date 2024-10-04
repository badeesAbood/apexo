import 'package:apexo/pages/page_staff.dart';
import 'package:apexo/pages/widgets/tag_input.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:fluent_ui/fluent_ui.dart';

class OperatorsPicker extends StatelessWidget {
  final List<String> value;
  final void Function(List<String>) onChanged;
  const OperatorsPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TagInputWidget(
      suggestions: staff.presentAndOperate.map((staff) => TagInputItem(value: staff.id, label: staff.title)).toList(),
      onChanged: (s) {
        onChanged(s.where((x) => x.value != null).map((x) => x.value!).toList());
      },
      initialValue: value.map((id) => TagInputItem(value: id, label: staff.get(id)!.title)).toList(),
      onItemTap: (tag) {
        Member? tapped = staff.get(tag.value ?? "");
        Map<String, dynamic> json = tapped != null ? tapped.toJson() : {};
        openSingleMember(
          context: context,
          json: json,
          title: "Staff member Details",
          onSave: staff.modify,
          editing: true,
        );
      },
      strict: true,
      limit: 999,
      placeholder: "Select operators",
    );
  }
}
