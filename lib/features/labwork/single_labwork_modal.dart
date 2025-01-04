import 'package:apexo/app/routes.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/common_widgets/call_button.dart';
import 'package:apexo/common_widgets/date_time_picker.dart';
import 'package:apexo/common_widgets/operators_picker.dart';
import 'package:apexo/common_widgets/patient_picker.dart';
import 'package:apexo/features/labwork/labwork_model.dart';
import 'package:apexo/features/labwork/labworks_store.dart';
import 'package:apexo/features/settings/settings_stores.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import "../../common_widgets/tabbed_modal.dart";

openSingleLabwork({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Labwork) onSave,
  required bool editing,
}) {
  routes.openLabwork = Labwork.fromJson(json);
  TextEditingController labNameController = TextEditingController(text: routes.openLabwork.lab);
  TextEditingController labPhoneController = TextEditingController(text: routes.openLabwork.phoneNumber);

  final o = routes.openLabwork;
  showTabbedModal(
      key: Key(o.id),
      context: context,
      streams: [labworks.observableObject.stream],
      onArchive: o.archived != true && editing ? () => labworks.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => labworks.set(o..archived = null) : null,
      onSave: () => labworks.set(routes.openLabwork),
      tabs: [
        TabbedModal(
          title: title,
          icon: FluentIcons.manufacturing,
          closable: true,
          spacing: 10,
          content: (state) => [
            InfoLabel(
              label: "${txt("date")}:",
              child: DateTimePicker(
                key: WK.fieldLabworkDate,
                value: o.date,
                onChange: (d) => o.date = d,
                buttonText: txt("changeDate"),
              ),
            ),
            InfoLabel(
              label: "${txt("patient")}:",
              child: PatientPicker(
                  value: o.patientID,
                  onChanged: (id) {
                    o.patientID = id;
                    state.rebuildSheet();
                  }),
            ),
            InfoLabel(
              label: "${txt("doctors")}:",
              child: OperatorsPicker(
                  value: o.operatorsIDs,
                  onChanged: (ids) {
                    o.operatorsIDs = ids;
                    state.rebuildSheet();
                  }),
            ),
            InfoLabel(
              label: "${txt("orderNotes")}:",
              child: CupertinoTextField(
                key: WK.fieldLabworkOrderNotes,
                controller: TextEditingController(text: o.note),
                placeholder: "${txt("orderNotes")}...",
                onChanged: (val) {
                  o.note = val;
                },
                maxLines: null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InfoLabel(
                    label: "${txt("priceIn")} ${globalSettings.get("currency_______").value}",
                    child: NumberBox(
                      key: WK.fieldLabworkPrice,
                      style: textFieldTextStyle(),
                      clearButton: false,
                      mode: SpinButtonPlacementMode.inline,
                      value: o.price,
                      onChanged: (n) => o.price = n ?? 0.0,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Padding(
                  padding: const EdgeInsets.only(top: 22.5),
                  child: ToggleSwitch(
                    key: WK.fieldLabworkPaidToggle,
                    checked: o.paid,
                    onChanged: (n) {
                      o.paid = n;
                      state.rebuildSheet();
                    },
                    content: o.paid ? Txt(txt("paid")) : Txt(txt("unpaid")),
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InfoLabel(
                    label: "${txt("laboratory")}:",
                    child: AutoSuggestBox<String>(
                      key: WK.fieldLabworkLabName,
                      style: textFieldTextStyle(),
                      decoration: textFieldDecoration(),
                      clearButtonEnabled: false,
                      placeholder: "${txt("laboratory")}...",
                      controller: labNameController,
                      noResultsFoundBuilder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Txt(txt("noSuggestions")),
                      ),
                      onChanged: (text, reason) {
                        o.lab = text;
                        String? phoneNumber = labworks.getPhoneNumber(text);
                        if (phoneNumber != null) {
                          labPhoneController.text = phoneNumber;
                          o.phoneNumber = phoneNumber;
                        }
                        state.rebuildSheet();
                      },
                      items:
                          labworks.allLabs.map((name) => AutoSuggestBoxItem<String>(value: name, label: name)).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InfoLabel(
                    label: "${txt("phone")}:",
                    child: AutoSuggestBox<String>(
                      key: WK.fieldLabworkPhoneNumber,
                      style: textFieldTextStyle(),
                      decoration: textFieldDecoration(),
                      clearButtonEnabled: false,
                      placeholder: "${txt("phone")}...",
                      controller: labPhoneController,
                      noResultsFoundBuilder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Txt(txt("noSuggestions")),
                      ),
                      onChanged: (text, reason) {
                        o.phoneNumber = text;
                        state.rebuildSheet();
                      },
                      trailingIcon: CallIconButton(phoneNumber: o.phoneNumber),
                      items: labworks.allPhones.map((pn) => AutoSuggestBoxItem<String>(value: pn, label: pn)).toList(),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ]);
}

BoxDecoration textFieldDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(5),
    border: Border.all(color: const Color.fromARGB(255, 192, 192, 192)),
  );
}

TextStyle textFieldTextStyle() {
  return const TextStyle(
    fontSize: 16,
  );
}
