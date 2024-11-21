import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/labwork/modal_labwork.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/state/stores/labworks/labwork_model.dart';
import 'package:apexo/state/stores/labworks/labworks_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import "../shared/datatable.dart";

class LabworksPage extends ObservingWidget {
  const LabworksPage({super.key});

  @override
  getObservableState() {
    return [labworks.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: DataTable<Labwork>(
        items: labworks.present.values.toList(),
        actions: [
          DataTableAction(
            callback: (_) => openSingleLabwork(
              context: context,
              json: {},
              title: txt("newLabwork"),
              onSave: labworks.set,
              editing: false,
            ),
            icon: FluentIcons.manufacturing,
            title: txt("add"),
          ),
          DataTableAction(
            callback: (ids) {
              for (var id in ids) {
                labworks.archive(id);
              }
            },
            icon: FluentIcons.archive,
            title: txt("archiveSelected"),
          )
        ],
        furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: labworks.notify)],
        onSelect: (item) => {
          openSingleLabwork(
              context: context, json: item.toJson(), title: txt("labwork"), onSave: labworks.set, editing: true)
        },
      ),
    );
  }
}
