import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/shared/transitions/border.dart';
import 'package:apexo/i18/index.dart';
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
        header: Text(txt("admins")),
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
      subtitle: "${txt("accountCreated")}: ${admin.created.split(" ").first}",
      actions: [
        if (state.email != admin.email) buildDeleteButton(admin),
        buildEditButton(admin, context),
      ],
      trailingText: state.email == admin.email
          ? Text(txt("you"), style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))
          : const SizedBox(),
    );
  }

  Tooltip buildEditButton(AdminModel admin, BuildContext context) {
    return Tooltip(
      message: txt("edit"),
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
      title: Text(txt("editAdmin")),
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
            admins.update(admin.id, emailController.text, passwordController.text);
          },
        ),
      ],
    );
  }

  Tooltip buildDeleteButton(AdminModel admin) {
    return Tooltip(
      message: txt("delete"),
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
                  children: [const Icon(FluentIcons.add), const SizedBox(width: 5), Text(txt("newAdmin"))]),
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(FluentIcons.save),
            const SizedBox(width: 5),
            Text(txt("save")),
          ]),
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
      message: txt("refresh"),
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
