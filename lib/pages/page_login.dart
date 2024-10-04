import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import "package:flutter/cupertino.dart" show CupertinoTextField;
import '../panel_logo.dart';
import '../state/state.dart';

class Login extends ObservingWidget {
  const Login({super.key});

  @override
  getObservableState() {
    return [state];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Center(
          child: SizedBox(
        width: 350,
        child: Acrylic(
          child: Container(
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(5),
                boxShadow: kElevationToShadow[24]),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const AppLogo(),
                const SizedBox(height: 20),
                if (state.loginError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: InfoBar(
                        title: const Text("Error"), content: Text(state.loginError), severity: InfoBarSeverity.error),
                  ),
                InfoLabel(
                  label: "Database URL",
                  child: CupertinoTextField(
                      controller: state.urlField, enabled: state.loadingIndicator.isEmpty && !state.showStaffPicker),
                ),
                const SizedBox(height: 10),
                InfoLabel(
                  label: "Token",
                  child: CupertinoTextField(
                      controller: state.tokenField, enabled: state.loadingIndicator.isEmpty && !state.showStaffPicker),
                ),
                const SizedBox(height: 20),
                if (state.loadingIndicator.isNotEmpty)
                  Column(
                    children: [
                      const ProgressBar(),
                      const SizedBox(height: 10),
                      Text(state.loadingIndicator),
                    ],
                  )
                else if (state.showStaffPicker)
                  Row(
                    children: [
                      SizedBox(
                          width: 139,
                          child: ComboBox<String>(
                              value: state.memberID,
                              onChanged: (id) {
                                state.memberID = id ?? "";
                                state.notify();
                              },
                              items: staff.present
                                  .map((s) => ComboBoxItem<String>(
                                      value: s.id,
                                      child: Text(s.title.length > 12 ? s.title.substring(0, 12) + "..." : s.title,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList())),
                      const SizedBox(width: 5),
                      Expanded(
                          child: CupertinoTextField(
                        placeholder: "PIN",
                        controller: state.pinField,
                      )),
                      SizedBox(width: 5),
                      FilledButton(
                          child: Row(
                            children: [Icon(FluentIcons.chevron_right), SizedBox(width: 5), Text("Continue")],
                          ),
                          onPressed: state.openAsCertainStaff)
                    ],
                  )
                else
                  Row(
                    children: [
                      FilledButton(
                        onPressed: state.loginButton,
                        child: const Row(children: [Icon(FluentIcons.forward), SizedBox(width: 10), Text("Login")]),
                      ),
                      const SizedBox(width: 10),
                      if (state.loginError.isNotEmpty)
                        FilledButton(
                          onPressed: () => state.loginButton(false),
                          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
                          child: const Row(children: [
                            Icon(FluentIcons.virtual_network),
                            SizedBox(width: 10),
                            Text("Proceed Offline")
                          ]),
                        ),
                    ],
                  ),
              ]),
            ),
          ),
        ),
      )),
    );
  }
}
