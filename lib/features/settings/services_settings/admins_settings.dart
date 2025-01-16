import 'package:apexo/common_widgets/button_styles.dart';
import 'package:apexo/common_widgets/dialogs/close_dialog_button.dart';
import 'package:apexo/common_widgets/dialogs/dialog_styling.dart';
import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/common_widgets/transitions/border.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/settings/services_settings/services_list_item.dart';
import 'package:apexo/services/admins.dart';
import 'package:apexo/services/login.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:pocketbase/pocketbase.dart';

class AdminsSettings extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  AdminsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.local_admin),
        header: Txt(txt("admins")),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: MStreamBuilder(
              streams: [
                admins.list.stream,
                admins.loaded.stream,
                admins.loading.stream,
                admins.creating.stream,
                admins.errorMessage.stream,
                admins.updating.stream,
                admins.deleting.stream,
              ],
              builder: (context, _) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List<Widget>.from(
                      admins.list().map(
                            (admin) => buildListItem(admin, context),
                          ),
                    ).followedBy([
                      const SizedBox(height: 10),
                      buildBottomControls(context),
                      const SizedBox(height: 10),
                      if (admins.errorMessage().isNotEmpty) buildErrorMsg()
                    ]).toList());
              }),
        ),
      ),
    );
  }

  InfoBar buildErrorMsg() {
    return InfoBar(
      title: Txt(admins.errorMessage()),
      severity: InfoBarSeverity.error,
    );
  }

  ServicesListItem buildListItem(RecordModel admin, BuildContext context) {
    return ServicesListItem(
      title: admin.getStringValue("email"),
      subtitle: "${txt("accountCreated")}: ${admin.get<String>("created").split(" ").first}",
      actions: [
        if (login.email != admin.getStringValue("email")) buildDeleteButton(admin),
        buildEditButton(admin, context),
      ],
      trailingText: login.email == admin.getStringValue("email")
          ? Txt(txt("you"), style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))
          : const SizedBox(),
    );
  }

  Tooltip buildEditButton(RecordModel admin, BuildContext context) {
    return Tooltip(
      message: txt("edit"),
      child: BorderColorTransition(
        animate: admins.updating().containsKey(admin.id),
        child: IconButton(
          icon: const Icon(FluentIcons.edit),
          onPressed: () {
            if (admins.updating().containsKey(admin.id)) return;
            showDialog(
                context: context,
                builder: (context) {
                  emailController.text = admin.getStringValue("email");
                  passwordController.text = "";
                  return editDialog(context, admin);
                });
          },
        ),
      ),
    );
  }

  ContentDialog editDialog(BuildContext context, RecordModel admin) {
    return ContentDialog(
      title: Txt(txt("editAdmin")),
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
            admins.update(admin.id, emailController.text, passwordController.text);
          },
        ),
      ],
    );
  }

  Tooltip buildDeleteButton(RecordModel admin) {
    return Tooltip(
      message: txt("delete"),
      child: BorderColorTransition(
        animate: admins.deleting().containsKey(admin.id),
        child: IconButton(
          icon: const Icon(FluentIcons.delete),
          onPressed: () {
            if (admins.deleting().containsKey(admin.id)) return;
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
                  children: [const Icon(FluentIcons.add), const SizedBox(width: 5), Txt(txt("newAdmin"))]),
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
      title: const Txt("New Admin"),
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(FluentIcons.save),
            const SizedBox(width: 5),
            Txt(txt("save")),
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
        animate: admins.loading(),
        child: IconButton(
          icon: const Icon(FluentIcons.sync, size: 17),
          iconButtonMode: IconButtonMode.large,
          onPressed: () {
            admins.errorMessage("");
            admins.reloadFromRemote();
          },
        ),
      ),
    );
  }
}
