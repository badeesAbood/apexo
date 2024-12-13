import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/global_actions.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/settings/window_admins.dart';
import 'package:apexo/pages/settings/window_backups.dart';
import 'package:apexo/pages/settings/window_permissions.dart';
import 'package:apexo/pages/settings/window_production_test.dart';
import 'package:apexo/pages/settings/window_users.dart';
import 'package:apexo/state/admins.dart';
import 'package:apexo/state/backups.dart';
import 'package:apexo/state/state.dart' as app_state;
import 'package:apexo/state/users.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../state/stores/settings/settings_model.dart';
import '../../state/stores/settings/settings_store.dart';

enum InputType { text, multiline, dropDown }

enum Scope { device, app }

class SettingsPage extends ObservingWidget {
  const SettingsPage({super.key});

  @override
  getObservableState() {
    return [globalSettings.observableObject, localSettings];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.settingsPage,
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ListView(
          children: [
            if (app_state.state.isAdmin)
              SettingsItem(
                title: txt("currency"),
                identifier: "currency",
                description: txt("currency_desc"),
                icon: FluentIcons.all_currency,
                inputType: InputType.text,
                scope: Scope.app,
                value: globalSettings.get("currency_______")!.value,
                apply: (newVal) => globalSettings.set(Setting.fromJson({"id": "currency_______", "value": newVal})),
              ),
            if (app_state.state.isAdmin)
              SettingsItem(
                title: txt("prescriptionFooter"),
                identifier: "prescriptionFot",
                description: txt("prescriptionFooter_desc"),
                icon: FluentIcons.footer,
                inputType: InputType.text,
                scope: Scope.app,
                value: globalSettings.get("prescriptionFot")!.value,
                apply: (newVal) => globalSettings.set(Setting.fromJson({"id": "prescriptionFot", "value": newVal})),
              ),
            if (app_state.state.isAdmin)
              SettingsItem(
                title: txt("phone"),
                identifier: "phone",
                description: txt("phone_desc"),
                icon: FluentIcons.phone,
                inputType: InputType.multiline,
                scope: Scope.app,
                value: globalSettings.get("phone__________")!.value,
                apply: (newVal) => globalSettings.set(Setting.fromJson({"id": "phone__________", "value": newVal})),
              ),
            SettingsItem(
              title: txt("language"),
              identifier: "language",
              description: txt("language_desc"),
              icon: FluentIcons.locale_language,
              inputType: InputType.dropDown,
              scope: Scope.device,
              options: locale.list.map((e) => ComboBoxItem(value: e.$code, child: Text(e.$name))).toList(),
              value: localSettings.locale,
              apply: (newVal) {
                localSettings.locale = newVal;
                localSettings.notify();
                locale.notify();
                globalActions.resync();
              },
            ),
            SettingsItem(
              title: txt("startingDayOfWeek"),
              identifier: "startingDayOfWeek",
              description: txt("startingDayOfWeek_desc"),
              icon: FluentIcons.hazy_day,
              inputType: InputType.dropDown,
              scope: Scope.app,
              options:
                  StartingDayOfWeek.values.map((e) => ComboBoxItem(value: e.name, child: Text(txt(e.name)))).toList(),
              value: globalSettings
                  .get("start_day_of_wk")!
                  .value, // TODO: bug: run fresh, proceed offline, and move to settings page
              apply: (newVal) => globalSettings.set(Setting.fromJson({"id": "start_day_of_wk", "value": newVal})),
            ),
            SettingsItem(
              title: txt("dateFormat"),
              identifier: "dateFormat",
              description: txt("dateFormat_desc"),
              icon: FluentIcons.calendar_settings,
              inputType: InputType.dropDown,
              scope: Scope.device,
              options: [
                ComboBoxItem(
                  value: "MM/dd/yyyy",
                  child: Text(txt("month/day/year")),
                ),
                ComboBoxItem(
                  value: "dd/MM/yyyy",
                  child: Text(txt("day/month/year")),
                ),
              ],
              value: localSettings.dateFormat,
              apply: (newVal) {
                localSettings.dateFormat = newVal;
                localSettings.notify();
              },
            ),
            if (app_state.state.isAdmin && app_state.state.isOnline) ...[
              const BackupsWindow(),
              AdminsWindow(),
              UsersWindow(),
              PermissionsWindow(),
              ProductionTestWindow(),
            ],
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
  final InputType inputType;
  final String identifier;
  final Scope scope;
  final List<ComboBoxItem<String>> options;
  String value;
  Function(String newVal) apply;

  SettingsItem({
    super.key,
    required this.identifier,
    required this.title,
    required this.description,
    required this.icon,
    required this.inputType,
    required this.scope,
    required this.value,
    required this.apply,
    this.options = const [],
  });

  @override
  State<StatefulWidget> createState() => SettingsItemState();
}

class SettingsItemState extends State<SettingsItem> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: Icon(widget.icon),
        header: Text(widget.title),
        content: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.inputType == InputType.text || widget.inputType == InputType.multiline)
                CupertinoTextField(
                  key: Key("${widget.identifier}_text_field"),
                  controller: _controller,
                  onChanged: (value) {
                    final currentPosition = _controller.selection;
                    setState(() => _controller.text = value);
                    _controller.selection = currentPosition;
                  },
                  maxLines: widget.inputType == InputType.multiline ? 1 : null,
                )
              else
                ComboBox<String>(
                  key: Key("${widget.identifier}_combo"),
                  items: widget.options,
                  onChanged: (value) => setState(() => value != null ? _controller.text = value : null),
                  value: _controller.text,
                ),
              const SizedBox(height: 5),
              Text(widget.description, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
              if (_controller.text != widget.value) buildSaveCancelButtons()
            ],
          ),
        ),
        initiallyExpanded: false,
        trailing: buildAppliesToIndicator(),
      ),
    );
  }

  Container buildAppliesToIndicator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.scope == Scope.app ? Colors.blue.withOpacity(0.05) : Colors.teal.withOpacity(0.05),
            widget.scope == Scope.app ? Colors.blue.withOpacity(0.14) : Colors.teal.withOpacity(0.14),
          ],
        ),
      ),
      child: Text(
        "${txt("appliesTo")}: ${widget.scope == Scope.app ? txt("all") : txt("you")} ",
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Row buildSaveCancelButtons() {
    return Row(
      children: [
        FilledButton(
          onPressed: () {
            setState(() {
              widget.value = _controller.text;
              widget.apply(_controller.text);
            });
            backups.notify();
            admins.notify();
            users.notify();
          },
          child: Row(children: [
            const Icon(FluentIcons.save),
            const SizedBox(width: 10),
            Text(txt("save")),
          ]),
        ),
        const SizedBox(width: 10),
        FilledButton(
          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
          onPressed: () {
            setState(() {
              _controller.text = widget.value;
            });
          },
          child: Row(children: [
            const Icon(FluentIcons.cancel),
            const SizedBox(width: 10),
            Text(txt("cancel")),
          ]),
        ),
      ],
    );
  }
}
