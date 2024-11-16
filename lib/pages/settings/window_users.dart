import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/backend/utils/transitions/border.dart';
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
        header: const Text("Users"),
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
      subtitle: "Account created: ${user.created.split(" ").first}",
      actions: [
        buildDeleteButton(user),
        buildEditButton(user, context),
      ],
      trailingText: const SizedBox(),
    );
  }

  Tooltip buildEditButton(RecordModel user, BuildContext context) {
    return Tooltip(
      message: "Edit",
      child: BorderColorTransition(
        animate: users.updating.containsKey(user.id),
        child: IconButton(
          icon: const Icon(FluentIcons.edit),
          onPressed: () {
            if (users.updating.containsKey(user.id)) return;
            showDialog(
                context: context,
                builder: (context) {
                  emailController.text = user.getStringValue("email");
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
      title: const Text("Edit User"),
      style: dialogStyling(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoLabel(
            label: "Email",
            child: CupertinoTextField(controller: emailController, placeholder: "Valid email must be provided"),
          ),
          const SizedBox(height: 15),
          InfoLabel(
            label: "Password",
            child: CupertinoTextField(
                controller: passwordController, obscureText: true, placeholder: "Leave blank to keep unchanged"),
          ),
          const SizedBox(height: 5),
          InfoBar(
              title: Text("Updating password"),
              content: Text("Leave the password field empty if you don't want to change it.")),
        ],
      ),
      actions: [
        const CloseButtonInDialog(),
        FilledButton(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(FluentIcons.save), SizedBox(width: 5), Text("Save")]),
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
      message: "Delete",
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
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(FluentIcons.add), SizedBox(width: 5), Text("New User")]),
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
      title: const Text("New User"),
      style: dialogStyling(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoLabel(
            label: "Email",
            child: CupertinoTextField(controller: emailController, placeholder: "Valid email must be provided"),
          ),
          const SizedBox(height: 15),
          InfoLabel(
            label: "Password",
            child: CupertinoTextField(
              controller: passwordController,
              obscureText: true,
              placeholder: "Minimum 10 characters password",
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
              children: [Icon(FluentIcons.save), SizedBox(width: 5), Text("Save")]),
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
      message: "Refresh",
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
