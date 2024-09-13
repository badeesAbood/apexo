import 'package:fluent_ui/fluent_ui.dart';
import '../../backend/observable/model.dart';
import '../../backend/observable/store.dart';
import './tabbed_modal.dart';

archiveButton(Model item, Store store) {
  return TabAction(
    text: item.archived == true ? "Unarchive" : "Archive",
    icon: item.archived == true ? FluentIcons.archive_undo : FluentIcons.archive_undo,
    color: item.archived == true ? Colors.grey : Colors.warningPrimaryColor,
    callback: () {
      item.archived = !(item.archived ?? false);
      store.modify(item);
      return true;
    },
  );
}
