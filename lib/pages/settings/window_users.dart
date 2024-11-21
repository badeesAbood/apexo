import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/backend/utils/transitions/border.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/shared/settings_list_tile.dart';
import 'package:apexo/pages/settings/window_backups.dart';
import 'package:apexo/state/users.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:pocketbase/pocketbase.dart';

// ignore: must_be_immutable
class UsersWindow extends ObservingWidget {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  UsersWindow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.people),
        header: Text(txt("users")),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.from(
                users.list.map(
                  (user) => buildListItem(user, context),
                ),
              ).followedBy([
                const SizedBox(height: 10),
                buildBottomControls(context),
                const SizedBox(height: 10),
                if (users.errorMessage.isNotEmpty) buildErrorMsg()
              ]).toList()),
        ),
      ),
    );
  }

  InfoBar buildErrorMsg() {
    return InfoBar(
      title: Text(users.errorMessage),
      severity: InfoBarSeverity.error,
    );
  }

  SettingsListTile buildListItem(RecordModel user, BuildContext context) {
    return SettingsListTile(
      title: user.getStringValue("email"),
      subtitle: "${txt("accountCreated")}: ${user.created.split(" ").first}",
      actions: [
        buildDeleteButton(user),
        buildEditButton(user, context),
      ],
      trailingText: const SizedBox(),
    );
  }

  Tooltip buildEditButton(RecordModel user, BuildContext context) {
    return Tooltip(
      message: txt("edit"),
      child: BorderColorTransition(
        animate: users.updating.containsKey(user.id),
        child: IconButton(
          icon: const Icon(FluentIcons.edit),
          onPressed: () {
            if (users.updating.containsKey(user.id)) return;
            showDialog(
                context: context,
                builder: (context) {
                  emailController.text = user.getStringValue(txt("email"));
                  passwordController.text = "";
                  return editDialog(context, user);
                });
          },
        ),
      ),
    );
  }

  ContentDialog editDialog(BuildContext context, RecordModel user) {
    return ContentDialog(
      title: Text(txt("editUser")),
      style: dialogStyling(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoLabel(
            label: txt("email"),
            child: CupertinoTextField(controller: emailController, placeholder: txt("validEmailMustBeProvided")),
          ),
          const SizedBox(height: 15),
          InfoLabel(
            label: txt("password"),
            child: CupertinoTextField(
                controller: passwordController, obscureText: true, placeholder: txt("leaveBlankToKeepUnchanged")),
          ),
          const SizedBox(height: 5),
          InfoBar(title: Text(txt("updatingPassword")), content: Text(txt("leaveItEmpty"))),
        ],
      ),
      actions: [
        const CloseButtonInDialog(),
        FilledButton(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Text(txt("save"))]),
          onPressed: () async {
            Navigator.pop(context);
            users.update(user.id, emailController.text, passwordController.text);
          },
        ),
      ],
    );
  }

  Tooltip buildDeleteButton(RecordModel user) {
    return Tooltip(
      message: txt("delete"),
      child: BorderColorTransition(
        animate: users.deleting.containsKey(user.id),
        child: IconButton(
          icon: const Icon(FluentIcons.delete),
          onPressed: () {
            if (users.deleting.containsKey(user.id)) return;
            users.delete(user);
          },
        ),
      ),
    );
  }

  Row buildBottomControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            FilledButton(
              style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      emailController.text = "";
                      passwordController.text = "";
                      return newDialog(context);
                    });
              },
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const Icon(FluentIcons.add), const SizedBox(width: 5), Text(txt("newUser"))]),
            ),
            const SizedBox(width: 10),
          ],
        ),
        buildRefreshButton()
      ],
    );
  }

  ContentDialog newDialog(BuildContext context) {
    return ContentDialog(
      title: Text(txt("newUser")),
      style: dialogStyling(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoLabel(
            label: txt("email"),
            child: CupertinoTextField(controller: emailController, placeholder: txt("validEmailMustBeProvided")),
          ),
          const SizedBox(height: 15),
          InfoLabel(
            label: txt("password"),
            child: CupertinoTextField(
              controller: passwordController,
              obscureText: true,
              placeholder: txt("minimumPasswordLength"),
            ),
          ),
        ],
      ),
      actions: [
        const CloseButtonInDialog(),
        FilledButton(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Text(txt("save"))]),
          onPressed: () async {
            Navigator.pop(context);
            users.newUser(emailController.text, passwordController.text);
          },
        ),
      ],
    );
  }

  Tooltip buildRefreshButton() {
    return Tooltip(
      message: txt("refresh"),
      child: BorderColorTransition(
        animate: users.loading,
        child: IconButton(
          icon: const Icon(FluentIcons.sync, size: 17),
          iconButtonMode: IconButtonMode.large,
          onPressed: () {
            users.errorMessage = "";
            users.reloadFromRemote();
          },
        ),
      ),
    );
  }

  @override
  List<ObservableBase> getObservableState() {
    return [users];
  }
}
