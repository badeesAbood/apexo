import 'package:apexo/backend/observable/store.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/settings/window_backups.dart';
import 'package:apexo/pages/shared/datatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

final flyoutController = FlyoutController();
DataTableAction archiveSelected(Store store) {
  return DataTableAction(
    callback: (ids) {
      if (ids.isEmpty) return;
      flyoutController.showFlyout(builder: (context) {
        return FlyoutContent(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${txt("sureArchiveSelected")} (${ids.length})"),
              const SizedBox(height: 12.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.warningPrimaryColor)),
                    onPressed: () {
                      Flyout.of(context).close();
                      for (var id in ids) {
                        store.archive(id);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(FluentIcons.archive, size: 16),
                        const SizedBox(width: 5),
                        Text(txt("archive")),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const CloseButtonInDialog(),
                ],
              ),
            ],
          ),
        );
      });
    },
    icon: FluentIcons.archive,
    child: FlyoutTarget(controller: flyoutController, child: Text(txt("archiveSelected"))),
  );
}
