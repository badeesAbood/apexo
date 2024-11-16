import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/backend/utils/transitions/border.dart';
import 'package:apexo/pages/shared/settings_list_tile.dart';
import 'package:apexo/pages/settings/window_backups.dart';
import 'package:apexo/state/admins.dart';
import 'package:apexo/state/state.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:pocketbase/src/dtos/admin_model.dart';

// ignore: must_be_immutable
class AdminsWindow extends ObservingWidget {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  AdminsWindow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.local_admin),
        header: const Text("Administrators"),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.from(
                admins.list.map(
                  (admin) => buildListItem(admin, context),
                ),
              ).followedBy([
                const SizedBox(height: 10),
                buildBottomControls(context),
                const SizedBox(height: 10),
                if (admins.errorMessage.isNotEmpty) buildErrorMsg()
              ]).toList()),
        ),
      ),
    );
  }

  InfoBar buildErrorMsg() {
    return InfoBar(
      title: Text(admins.errorMessage),
      severity: InfoBarSeverity.error,
    );
  }

  SettingsListTile buildListItem(AdminModel admin, BuildContext context) {
    return SettingsListTile(
      title: admin.email,
      subtitle: "Account created: ${admin.created.split(" ").first}",
      actions: [
        if (state.email != admin.email) buildDeleteButton(admin),
        buildEditButton(admin, context),
      ],
      trailingText: state.email == admin.email
          ? Text("You", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))
          : const SizedBox(),
    );
  }

  Tooltip buildEditButton(AdminModel admin, BuildContext context) {
    return Tooltip(
      message: "Edit",
      child: BorderColorTransition(
        animate: admins.updating.containsKey(admin.id),
        child: IconButton(
          icon: const Icon(FluentIcons.edit),
          onPressed: () {
            if (admins.updating.containsKey(admin.id)) return;
            showDialog(
                context: context,
                builder: (context) {
                  emailController.text = admin.email;
                  passwordController.text = "";
                  return editDialog(context, admin);
                });
          },
        ),
      ),
    );
  }

  ContentDialog editDialog(BuildContext context, AdminModel admin) {
    return ContentDialog(
      title: const Text("Edit Admin"),
      style: dialogStyling(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoLabel(
            label: "Email",
            child: CupertinoTextField(controller: emailController, placeholder: "Valid email must be provided"),
          ),
          SizedBox(height: 15),
          InfoLabel(
            label: "Password",
            child: CupertinoTextField(
                controller: passwordController, obscureText: true, placeholder: "Leave blank to keep unchanged"),
          ),
          SizedBox(height: 5),
          InfoBar(
              title: Text("Updating password"),
              content: Text("Leave the password field empty if you don't want to change it.")),
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
            admins.update(admin.id, emailController.text, passwordController.text);
          },
        ),
      ],
    );
  }

  Tooltip buildDeleteButton(AdminModel admin) {
    return Tooltip(
      message: "Delete",
      child: BorderColorTransition(
        animate: admins.deleting.containsKey(admin.id),
        child: IconButton(
          icon: const Icon(FluentIcons.delete),
          onPressed: () {
            if (admins.deleting.containsKey(admin.id)) return;
            admins.delete(admin);
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
                  children: [Icon(FluentIcons.add), SizedBox(width: 5), Text("New Admin")]),
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
      title: const Text("New Admin"),
      style: dialogStyling(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoLabel(
            label: "Email",
            child: CupertinoTextField(controller: emailController, placeholder: "Valid email must be provided"),
          ),
          SizedBox(height: 15),
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
            admins.newAdmin(emailController.text, passwordController.text);
          },
        ),
      ],
    );
  }

  Tooltip buildRefreshButton() {
    return Tooltip(
      message: "Refresh",
      child: BorderColorTransition(
        animate: admins.loading,
        child: IconButton(
          icon: const Icon(FluentIcons.sync, size: 17),
          iconButtonMode: IconButtonMode.large,
          onPressed: () {
            admins.errorMessage = "";
            admins.reloadFromRemote();
          },
        ),
      ),
    );
  }

  @override
  List<ObservableBase> getObservableState() {
    return [admins];
  }
}
