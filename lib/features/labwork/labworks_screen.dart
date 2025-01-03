import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/labwork/single_labwork_modal.dart';
import 'package:apexo/common_widgets/archive_selected.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/features/labwork/labwork_model.dart';
import 'package:apexo/features/labwork/labworks_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import "../../common_widgets/datatable.dart";

class LabworksScreen extends StatelessWidget {
  const LabworksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.labworksScreen,
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          Expanded(
            child: StreamBuilder(
                stream: labworks.observableObject.stream,
                builder: (context, snapshot) {
                  return DataTable<Labwork>(
                    compact: true,
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
                      archiveSelected(labworks)
                    ],
                    furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: labworks.notify)],
                    onSelect: (item) => {
                      openSingleLabwork(
                          context: context,
                          json: item.toJson(),
                          title: txt("labwork"),
                          onSave: labworks.set,
                          editing: true)
                    },
                    itemActions: [
                      ItemAction(
                        icon: FluentIcons.phone,
                        title: txt("callLaboratory"),
                        callback: (id) {
                          final lab = labworks.get(id);
                          if (lab == null) return;
                          launchUrl(Uri.parse('tel:${lab.phoneNumber}'));
                        },
                      ),
                      ItemAction(
                        icon: FluentIcons.archive,
                        title: txt("archive"),
                        callback: (id) {
                          labworks.archive(id);
                        },
                      ),
                    ],
                    defaultSortDirection: -1,
                    defaultSortingName: "byDate",
                  );
                }),
          ),
        ],
      ),
    );
  }
}
