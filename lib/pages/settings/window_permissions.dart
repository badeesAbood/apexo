import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/state/permissions.dart';
import 'package:fluent_ui/fluent_ui.dart';

// ignore: must_be_immutable
class PermissionsWindow extends ObservingWidget {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  PermissionsWindow({
    super.key,
  });

  List<String> permissionsTitles = const ["staff", "patients", "appointments", "labworks", "statistics"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.permissions),
        header: Text(txt("permissions")),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBar(
                  title: Text(txt("permissions")),
                  severity: InfoBarSeverity.warning,
                  content: Text(txt("permissionsNotice")),
                ),
                ...List.generate(
                    permissions.list.length,
                    (index) => ToggleSwitch(
                          checked: permissions.editingList[index],
                          onChanged: (val) {
                            permissions.editingList[index] = val;
                            permissions.notify();
                          },
                          content: Text("${txt("usersCanAccess")} ${txt(permissionsTitles[index])}"),
                        )),
                if (permissions.edited) ...[
                  const SizedBox(),
                  Row(
                    children: [
                      FilledButton(
                        child: Row(
                          children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Text(txt("save"))],
                        ),
                        onPressed: () {
                          permissions.save();
                        },
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        child: Row(
                          children: [const Icon(FluentIcons.reset), const SizedBox(width: 5), Text(txt("reset"))],
                        ),
                        onPressed: () {
                          permissions.reset();
                        },
                      ),
                    ],
                  )
                ]
              ].map((e) => [e, const SizedBox(height: 10)]).expand((e) => e).toList()),
        ),
      ),
    );
  }

  @override
  List<ObservableBase> getObservableState() {
    return [permissions];
  }
}
