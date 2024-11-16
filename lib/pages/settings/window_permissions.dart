import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/state/permissions.dart';
import 'package:fluent_ui/fluent_ui.dart';

// ignore: must_be_immutable
class PermissionsWindow extends ObservingWidget {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  PermissionsWindow({
    super.key,
  });

  List<String> permissionsTitles = const ["staff members", "patients", "appointments", "labworks", "statistics"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.permissions),
        header: const Text("User Permissions"),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoBar(
                  title: Text("Permissions"),
                  severity: InfoBarSeverity.warning,
                  content: Text(
                      "The followng persmission apply to the users listed above. However, adminstrators like you, have unrestricted access in the application."),
                ),
                ...List.generate(
                    permissions.list.length,
                    (index) => ToggleSwitch(
                          checked: permissions.editingList[index],
                          onChanged: (val) {
                            permissions.editingList[index] = val;
                            permissions.notify();
                          },
                          content: Text("Users can access ${permissionsTitles[index]}"),
                        )),
                if (permissions.edited) ...[
                  const SizedBox(),
                  Row(
                    children: [
                      FilledButton(
                        child: Row(
                          children: [Icon(FluentIcons.save), SizedBox(width: 5), Text("Save")],
                        ),
                        onPressed: () {
                          permissions.save();
                        },
                      ),
                      SizedBox(width: 10),
                      FilledButton(
                        child: Row(
                          children: [Icon(FluentIcons.reset), SizedBox(width: 5), Text("Reset")],
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
