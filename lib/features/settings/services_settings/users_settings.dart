import 'package:apexo/common_widgets/button_styles.dart';
import 'package:apexo/common_widgets/dialogs/close_dialog_button.dart';
import 'package:apexo/common_widgets/dialogs/dialog_styling.dart';
import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/common_widgets/transitions/border.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/settings/services_settings/services_list_item.dart';
import 'package:apexo/services/users.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:pocketbase/pocketbase.dart';

class UsersSettings extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  UsersSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.people),
        header: Txt(txt("users")),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: MStreamBuilder(
              streams: [
                users.list.stream,
                users.loaded.stream,
                users.loading.stream,
                users.creating.stream,
                users.errorMessage.stream,
                users.updating.stream,
                users.deleting.stream,
              ],
              builder: (context, _) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List<Widget>.from(
                      users.list().map(
                            (user) => buildListItem(user, context),
                          ),
                    ).followedBy([
                      const SizedBox(height: 10),
                      buildBottomControls(context),
                      const SizedBox(height: 10),
                      if (users.errorMessage().isNotEmpty) buildErrorMsg()
                    ]).toList());
              }),
        ),
      ),
    );
  }

  InfoBar buildErrorMsg() {
    return InfoBar(
      title: Txt(users.errorMessage()),
      severity: InfoBarSeverity.error,
    );
  }

  ServicesListItem buildListItem(RecordModel user, BuildContext context) {
    return ServicesListItem(
      title: user.getStringValue("email"),
      subtitle: "${txt("accountCreated")}: ${user.get<String>("created").split(" ").first}",
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
        animate: users.updating().containsKey(user.id),
        child: IconButton(
          icon: const Icon(FluentIcons.edit),
          onPressed: () {
            if (users.updating().containsKey(user.id)) return;
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
      title: Txt(txt("editUser")),
      style: dialogStyling(context, false),
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
          InfoBar(title: Txt(txt("updatingPassword")), content: Txt(txt("leaveItEmpty"))),
        ],
      ),
      actions: [
        const CloseButtonInDialog(),
        FilledButton(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Txt(txt("save"))]),
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
        animate: users.deleting().containsKey(user.id),
        child: IconButton(
          icon: const Icon(FluentIcons.delete),
          onPressed: () {
            if (users.deleting().containsKey(user.id)) return;
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
              style: greyButtonStyle.copyWith(backgroundColor: const WidgetStatePropertyAll(Colors.grey)),
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
                  children: [const Icon(FluentIcons.add), const SizedBox(width: 5), Txt(txt("newUser"))]),
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
      title: Txt(txt("newUser")),
      style: dialogStyling(context, false),
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
              children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Txt(txt("save"))]),
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
        animate: users.loading(),
        child: IconButton(
          icon: const Icon(FluentIcons.sync, size: 17),
          iconButtonMode: IconButtonMode.large,
          onPressed: () {
            users.errorMessage("");
            users.reloadFromRemote();
          },
        ),
      ),
    );
  }
}
