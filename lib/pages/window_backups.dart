import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/backend/utils/get_deterministic_item.dart';
import 'package:apexo/backend/utils/transitions/border.dart';
import 'package:apexo/pages/widgets/settings_list_tile.dart';
import 'package:apexo/state/backups.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// TODO: we may need to refactor how views and widgets are sorted throught the project
// some widgets might be best to be kept in a single file like this one
// should we keep them under pages?
// also look at the widgets folder! does it make sense to have a folder called "widgets"?!
// maybe we can sort them into "pages" and "windows"
// page_settings.dart
// window_backups.dart

class BackupsWindow extends ObservingWidget {
  const BackupsWindow({
    super.key,
  });

  String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = 0;
    var value = bytes.toDouble();

    while (value >= 1024 && i < suffixes.length - 1) {
      value /= 1024;
      i++;
    }

    return '${value.toStringAsPrecision(3)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.folder),
        header: Text("Backups"),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.from(backups.list.map((element) => buildBackupTile(element, context)))
                  .followedBy([const SizedBox(height: 10), buildBottomControls()]).toList()),
        ),
      ),
    );
  }

  Widget buildBackupTile(BackupFile element, BuildContext context) {
    return SettingsListTile(
      title: DateFormat("d/MM/yy hh:mm a").format(element.date),
      subtitle: element.key,
      actions: [
        buildDownloadButton(element, context),
        buildDeleteButton(element, context),
        buildRestoreButton(element, context)
      ],
      trailingText: buildFileSize(element),
    );
  }

  Row buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            buildCreateNewBackupButton(),
            const SizedBox(width: 10),
            buildUploadBackupButton(),
          ],
        ),
        buildRefreshButton()
      ],
    );
  }

  Tooltip buildRefreshButton() {
    return Tooltip(
      message: "Refresh",
      child: BorderColorTransition(
        animate: backups.loading,
        child: IconButton(
          icon: const Icon(FluentIcons.sync, size: 17),
          iconButtonMode: IconButtonMode.large,
          onPressed: backups.reloadFromRemote,
        ),
      ),
    );
  }

  BorderColorTransition buildUploadBackupButton() {
    return BorderColorTransition(
      animate: backups.uploading,
      child: Button(
        style: backups.uploading
            ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey.withOpacity(0.1)))
            : null,
        child: Row(
          children: [
            const Icon(FluentIcons.upload),
            const SizedBox(width: 10),
            Text("Upload"),
          ],
        ),
        onPressed: () {
          if (backups.uploading) return;
          backups.pickAndUpload();
        },
      ),
    );
  }

  BorderColorTransition buildCreateNewBackupButton() {
    return BorderColorTransition(
      animate: backups.creating,
      child: Button(
        style: backups.creating
            ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey.withOpacity(0.1)))
            : null,
        child: Row(
          children: [
            const Icon(FluentIcons.add),
            const SizedBox(width: 10),
            Text("Create new"),
          ],
        ),
        onPressed: () {
          if (backups.creating) return;
          backups.newBackup();
        },
      ),
    );
  }

  Container buildFileSize(BackupFile element) {
    return Container(
      padding: EdgeInsets.all(7),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: getDeterministicItem(Colors.accentColors, element.key).withOpacity(0.1)),
      child: Text(formatFileSize(element.size), style: const TextStyle(fontSize: 12)),
    );
  }

  Tooltip buildRestoreButton(BackupFile element, BuildContext context) {
    return Tooltip(
      message: "Restore",
      child: BorderColorTransition(
        animate: backups.restoring.containsKey(element.key),
        child: IconButton(
          icon: const Icon(FluentIcons.update_restore),
          onPressed: () {
            if (backups.restoring.containsKey(element.key)) return;
            showRestoreDialog(context, element);
          },
        ),
      ),
    );
  }

  showRestoreDialog(BuildContext context, BackupFile element) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ContentDialog(
            title: const Text("Restore backup"),
            style: dialogStyling(true),
            content: Text(
                "Restoring this backup will overwrite all data in the app currently. Any changes that you have made after the date of this backup (${DateFormat().format(element.date)}) will be lost.\n\nAre you sure you want to continue?"),
            actions: [
              const CloseButtonInDialog(),
              FilledButton(
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)),
                child: const Text("Restore"),
                onPressed: () async {
                  Navigator.pop(context);
                  await backups.restore(element.key);
                },
              ),
            ],
          );
        });
  }

  Tooltip buildDeleteButton(BackupFile element, BuildContext context) {
    return Tooltip(
      message: "Delete",
      child: BorderColorTransition(
        animate: backups.deleting.containsKey(element.key),
        child: IconButton(
          icon: const Icon(FluentIcons.delete),
          onPressed: () {
            if (backups.deleting.containsKey(element.key)) return;
            showDeleteDialog(context, element);
          },
        ),
      ),
    );
  }

  showDeleteDialog(BuildContext context, BackupFile element) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ContentDialog(
            title: const Text("Delete backup"),
            style: dialogStyling(true),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Are you sure you want to delete the backup '${element.key}'?"),
                Text("Backup date: ${DateFormat().format(element.date)}"),
              ],
            ),
            actions: [
              const CloseButtonInDialog(),
              FilledButton(
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)),
                child: const Text("Delete"),
                onPressed: () async {
                  Navigator.pop(context);
                  await backups.delete(element.key);
                },
              ),
            ],
          );
        });
  }

  Tooltip buildDownloadButton(BackupFile element, BuildContext context) {
    return Tooltip(
      message: "Download",
      child: BorderColorTransition(
        animate: backups.downloading.containsKey(element.key),
        child: IconButton(
          icon: const Icon(FluentIcons.download),
          onPressed: () async {
            if (backups.downloading.containsKey(element.key)) return;
            final uri = await backups.downloadUri(element.key);
            if (context.mounted) {
              showDownloadDialog(context, uri);
            }
          },
        ),
      ),
    );
  }

  showDownloadDialog(BuildContext context, Uri uri) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ContentDialog(
            title: const Text("Download backup"),
            style: dialogStyling(false),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Use the following link to download the backup:"),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: TextEditingController(text: uri.toString()),
                ),
              ],
            ),
            actions: const [
              SizedBox(),
              SizedBox(),
              CloseButtonInDialog(),
            ],
          );
        });
  }

  @override
  List<ObservableBase> getObservableState() {
    return [backups];
  }
}

class CloseButtonInDialog extends StatelessWidget {
  const CloseButtonInDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.black)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(FluentIcons.cancel), SizedBox(width: 10), Text("Close")],
      ),
      onPressed: () => Navigator.pop(context),
    );
  }
}

ContentDialogThemeData dialogStyling(bool danger) {
  return ContentDialogThemeData(
    actionsDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.all(Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: (danger ? Colors.red : Colors.grey).withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 1),
          )
        ]),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        gradient: LinearGradient(colors: [Colors.white, danger ? Colors.errorSecondaryColor : Colors.white])),
    titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
  );
}
