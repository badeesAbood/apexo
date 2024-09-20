import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/cupertino.dart';
import '../backend/observable/store.dart';
import '../state/stores/settings/settings_model.dart';
import '../state/stores/settings/settings_store.dart';

enum InputType { text, dropDown }

enum Scope { device, app }

class PageTwo extends ObservingWidget {
  const PageTwo({super.key});

  @override
  getObservableState() {
    return [globalSettings.observableObject, localSettings.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ListView(
          children: [
            SettingsItem(
              identifier: "currency",
              title: "Currency",
              description: "Currency symbol to be used across the application",
              icon: FluentIcons.all_currency,
              inputType: InputType.text,
              scope: Scope.app,
            ),
            SettingsItem(
              identifier: "phone",
              title: "Phone number",
              description: "All calls will be transferred to this phone number",
              icon: FluentIcons.phone,
              inputType: InputType.text,
              scope: Scope.app,
            ),
            SettingsItem(
              identifier: "locale",
              title: "App language",
              description: "The interface language for the menus, buttons, and info used across the app",
              icon: FluentIcons.locale_language,
              inputType: InputType.dropDown,
              scope: Scope.device,
              options: const [
                ComboBoxItem(
                  value: "english",
                  child: Text("English"),
                ),
                ComboBoxItem(
                  value: "arabic",
                  child: Text("Arabic"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class SettingsItem extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String identifier;
  final InputType inputType;
  final Scope scope;
  final List<ComboBoxItem<String>> options;
  Setting? entry;

  SettingsItem({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.identifier,
    required this.inputType,
    required this.scope,
    this.options = const [],
  }) {
    var docsCheck = settings.getIndex(identifier);
    if (docsCheck == -1) {
      // settings.add(Setting.fromJson({"id": identifier, "value": defaultValue}));
    } else {
      entry = settings.get(identifier);
    }
  }

  Store<Setting> get settings {
    return scope == Scope.device ? localSettings : globalSettings;
  }

  @override
  State<StatefulWidget> createState() => SettingsItemState();
}

class SettingsItemState extends State<SettingsItem> {
  final TextEditingController _controller = TextEditingController();

  load() async {
    await widget.settings.loaded;
    setState(() {
      if (widget.settings.getIndex(widget.identifier) == -1) {
        widget.entry =
            Setting.fromJson({"id": widget.identifier, "value": "ERROR: unidentified setting, try restarting"});
      } else {
        widget.entry = widget.settings.get(widget.identifier);
      }
      _controller.text = widget.entry!.value;
    });
  }

  @override
  initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return widget.entry == null
        ? Text("Loading")
        : Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Expander(
              leading: Icon(widget.icon),
              header: Text(widget.title),
              content: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.inputType == InputType.text)
                      CupertinoTextField(
                        controller: _controller,
                        onChanged: (value) => setState(() => _controller.text = value),
                      )
                    else
                      ComboBox<String>(
                        items: widget.options,
                        onChanged: (value) => setState(() => value != null ? _controller.text = value : null),
                        value: _controller.text,
                      ),
                    SizedBox(height: 5),
                    Text(widget.description, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    SizedBox(height: 10),
                    if (_controller.text != widget.entry!.value)
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                widget.entry!.value = _controller.text;
                                widget.settings.modify(widget.entry!);
                              });
                            },
                            child: Row(children: const [Icon(FluentIcons.save), SizedBox(width: 10), Text("Save")]),
                          ),
                          SizedBox(width: 10),
                          FilledButton(
                            style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
                            onPressed: () {
                              setState(() {
                                _controller.text = widget.entry!.value;
                              });
                            },
                            child: Row(children: const [Icon(FluentIcons.cancel), SizedBox(width: 10), Text("Cancel")]),
                          ),
                        ],
                      )
                  ],
                ),
              ),
              initiallyExpanded: false,
              trailing: Container(
                padding: EdgeInsets.fromLTRB(7, 5, 7, 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.scope == Scope.app ? Colors.blue.withOpacity(0.05) : Colors.teal.withOpacity(0.05),
                        widget.scope == Scope.app ? Colors.blue.withOpacity(0.14) : Colors.teal.withOpacity(0.14),
                      ],
                    )),
                child: Text(
                  "Applies to: ${widget.scope == Scope.app ? "all" : "you"} ",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          );
  }
}
