import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/features/network_actions/network_actions_controller.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/settings/services_settings/admins_settings.dart';
import 'package:apexo/features/settings/services_settings/backups_settings.dart';
import 'package:apexo/features/settings/services_settings/permissions_settings.dart';
import 'package:apexo/features/settings/services_settings/production_test.dart';
import 'package:apexo/features/settings/services_settings/users_settings.dart';
import 'package:apexo/services/login.dart';
import 'package:apexo/services/network.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'settings_model.dart';
import 'settings_stores.dart';

enum InputType { text, multiline, dropDown }

enum Scope { device, app }

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.settingsScreen,
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ListView(
          children: [
            if (login.isAdmin)
              SettingsItem(
                title: txt("currency"),
                identifier: "currency",
                description: txt("currency_desc"),
                icon: FluentIcons.all_currency,
                inputType: InputType.text,
                scope: Scope.app,
                value: globalSettings.get("currency_______").value,
                apply: (newVal) => globalSettings.set(Setting.fromJson({"id": "currency_______", "value": newVal})),
              ),
            if (login.isAdmin)
              SettingsItem(
                title: txt("prescriptionFooter"),
                identifier: "prescriptionFot",
                description: txt("prescriptionFooter_desc"),
                icon: FluentIcons.footer,
                inputType: InputType.text,
                scope: Scope.app,
                value: globalSettings.get("prescriptionFot").value,
                apply: (newVal) => globalSettings.set(Setting.fromJson({"id": "prescriptionFot", "value": newVal})),
              ),
            if (login.isAdmin)
              SettingsItem(
                title: txt("phone"),
                identifier: "phone",
                description: txt("phone_desc"),
                icon: FluentIcons.phone,
                inputType: InputType.multiline,
                scope: Scope.app,
                value: globalSettings.get("phone__________").value,
                apply: (newVal) => globalSettings.set(Setting.fromJson({"id": "phone__________", "value": newVal})),
              ),
            SettingsItem(
              title: txt("language"),
              identifier: "language",
              description: txt("language_desc"),
              icon: FluentIcons.locale_language,
              inputType: InputType.dropDown,
              scope: Scope.device,
              options: locale.list.map((e) => ComboBoxItem(value: e.$code, child: Txt(e.$name))).toList(),
              value: localSettings.locale,
              apply: (newVal) {
                localSettings.locale = newVal;
                localSettings.notifyAndPersist();
                networkActions.resync();
              },
            ),
            if (login.isAdmin)
              SettingsItem(
                title: txt("startingDayOfWeek"),
                identifier: "startingDayOfWeek",
                description: txt("startingDayOfWeek_desc"),
                icon: FluentIcons.hazy_day,
                inputType: InputType.dropDown,
                scope: Scope.app,
                options:
                    StartingDayOfWeek.values.map((e) => ComboBoxItem(value: e.name, child: Txt(txt(e.name)))).toList(),
                value: globalSettings.get("start_day_of_wk").value,
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
                  child: Txt(txt("month/day/year")),
                ),
                ComboBoxItem(
                  value: "dd/MM/yyyy",
                  child: Txt(txt("day/month/year")),
                ),
              ],
              value: localSettings.dateFormat,
              apply: (newVal) {
                localSettings.dateFormat = newVal;
                localSettings.notifyAndPersist();
              },
            ),
            if (login.isAdmin && network.isOnline()) ...[
              const BackupsSettings(),
              AdminsSettings(),
              UsersSettings(),
              PermissionsSettings(),
              ProductionTests(),
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
        header: Txt(widget.title),
        content: SizedBox(
          width: 400,
          child: MStreamBuilder(
              streams: [globalSettings.observableMap.stream, localSettings.stream],
              builder: (context, _) {
                return Column(
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
                    Txt(widget.description, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    if (_controller.text != widget.value) buildSaveCancelButtons()
                  ],
                );
              }),
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
            widget.scope == Scope.app ? Colors.blue.withValues(alpha: 0.05) : Colors.teal.withValues(alpha: 0.05),
            widget.scope == Scope.app ? Colors.blue.withValues(alpha: 0.14) : Colors.teal.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Txt(
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
          },
          child: Row(children: [
            const Icon(FluentIcons.save),
            const SizedBox(width: 10),
            Txt(txt("save")),
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
            Txt(txt("cancel")),
          ]),
        ),
      ],
    );
  }
}
