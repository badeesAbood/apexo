import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/staff/modal_staff.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:apexo/state/stores/staff/member_model.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import "../shared/datatable.dart";

class StaffMembers extends ObservingWidget {
  const StaffMembers({super.key});

  @override
  getObservableState() {
    return [staff.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.staffPage,
      padding: EdgeInsets.zero,
      content: DataTable<Member>(
        items: staff.showing.values.toList(),
        actions: [
          DataTableAction(
            callback: (_) => openSingleMember(
              context: context,
              json: {},
              title: "${txt("add")} ${txt("doctor")}",
              onSave: staff.set,
              editing: false,
            ),
            icon: FluentIcons.medical,
            title: txt("add"),
          ),
          DataTableAction(
            callback: (ids) {
              for (var id in ids) {
                staff.archive(id);
              }
            },
            icon: FluentIcons.archive,
            title: txt("archiveSelected"),
          )
        ],
        furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: staff.notify)],
        onSelect: (item) => openSingleMember(
          context: context,
          json: item.toJson(),
          title: "${txt("edit")} ${txt("doctor")}",
          onSave: staff.set,
          editing: true,
        ),
      ),
    );
  }
}
