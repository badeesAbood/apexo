import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/backend/utils/get_deterministic_item.dart';
import 'package:apexo/pages/shared/transitions/border.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/shared/settings_list_tile.dart';
import 'package:apexo/state/backups.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

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
        header: Text(txt("backups")),
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
    final df = localSettings.dateFormat.startsWith("d") == true ? "d/MM" : "MM/d";
    return SettingsListTile(
      title: DateFormat("$df/yy hh:mm a", locale.s.$code).format(element.date),
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
      message: txt("refresh"),
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
            ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.1)))
            : null,
        child: Row(
          children: [
            const Icon(FluentIcons.upload),
            const SizedBox(width: 10),
            Text(txt("upload")),
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
            ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.1)))
            : null,
        child: Row(
          children: [
            const Icon(FluentIcons.add),
            const SizedBox(width: 10),
            Text(txt("createNew")),
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
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: getDeterministicItem(Colors.accentColors, element.key).withValues(alpha: 0.1)),
      child: Text(formatFileSize(element.size), style: const TextStyle(fontSize: 12)),
    );
  }

  Tooltip buildRestoreButton(BackupFile element, BuildContext context) {
    return Tooltip(
      message: txt("restoreBackup"),
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
            title: Text(txt("restoreBackup")),
            style: dialogStyling(true),
            content: Text(
                "${txt("restoreBackupWarning1")} (${DateFormat().format(element.date)}) ${txt("restoreBackupWarning2")}"),
            actions: [
              const CloseButtonInDialog(),
              FilledButton(
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)),
                child: Text(txt("restore")),
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
      message: txt("delete"),
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
            title: Text(txt("delete")),
            style: dialogStyling(true),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${txt("sureDeleteBackup")}: '${element.key}'?"),
                Text("${txt("backupDate")}: ${DateFormat().format(element.date)}"),
              ],
            ),
            actions: [
              const CloseButtonInDialog(),
              FilledButton(
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)),
                child: Text(txt("delete")),
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
      message: txt("download"),
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
            title: Text(txt("download")),
            style: dialogStyling(false),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${txt("useTheFollowingLinkToDownloadTheBackup")}:"),
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
  final String buttonText;
  const CloseButtonInDialog({
    this.buttonText = "cancel",
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.black)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [const Icon(FluentIcons.cancel), const SizedBox(width: 10), Text(txt(buttonText))],
      ),
      onPressed: () => Navigator.pop(context),
    );
  }
}

ContentDialogThemeData dialogStyling(bool danger) {
  return ContentDialogThemeData(
    actionsDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: (danger ? Colors.red : Colors.grey).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          )
        ]),
    decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        gradient: LinearGradient(colors: [Colors.white, danger ? Colors.errorSecondaryColor : Colors.white])),
    titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
  );
}
