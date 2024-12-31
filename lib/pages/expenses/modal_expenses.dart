import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/shared/call_button.dart';
import 'package:apexo/pages/shared/date_time_picker.dart';
import 'package:apexo/pages/shared/tag_input.dart';
import 'package:apexo/state/stores/expenses/expenses_model.dart';
import 'package:apexo/state/stores/expenses/expenses_store.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import "../shared/tabbed_modal.dart";

openSingleReceipt({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Expense) onSave,
  required bool editing,
}) {
  pages.openExpense = Expense.fromJson(json);

  TextEditingController issuerController = TextEditingController(text: pages.openExpense.issuer);
  TextEditingController issuerPhoneController = TextEditingController(text: pages.openExpense.phoneNumber);

  final o = pages.openExpense;
  showTabbedModal(
      key: Key(o.id),
      context: context,
      onArchive: o.archived != true && editing ? () => expenses.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => expenses.set(o..archived = null) : null,
      onSave: () => expenses.set(pages.openExpense),
      tabs: [
        TabbedModal(
          title: title,
          icon: FluentIcons.receipt_processing,
          closable: true,
          spacing: 10,
          content: (state) => [
            InfoLabel(
              label: "${txt("date")}:",
              child: DateTimePicker(
                key: WK.fieldReceiptDate,
                value: o.date,
                onChange: (d) => o.date = d,
                buttonText: txt("changeDate"),
              ),
            ),
            InfoLabel(
              label: "${txt("receiptItems")}:",
              isHeader: true,
              child: TagInputWidget(
                key: WK.fieldReceiptItems,
                suggestions: expenses.allItems.map((t) => TagInputItem(value: t, label: t)).toList(),
                onChanged: (items) {
                  pages.openExpense.items = List<String>.from(items.map((e) => e.value).where((e) => e != null));
                },
                initialValue: pages.openExpense.items.map((e) => TagInputItem(value: e, label: e)).toList(),
                strict: false,
                limit: 9999,
                placeholder: "${txt("receiptItems")}...",
              ),
            ),
            InfoLabel(
              label: "${txt("receiptNotes")}:",
              child: CupertinoTextField(
                key: WK.fieldReceiptNotes,
                controller: TextEditingController(text: o.note),
                placeholder: "${txt("receiptNotes")}...",
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
                    label: "${txt("amountIn")} ${globalSettings.get("currency_______").value}",
                    child: NumberBox(
                      key: WK.fieldReceiptAmount,
                      style: textFieldTextStyle(),
                      clearButton: false,
                      mode: SpinButtonPlacementMode.inline,
                      value: o.amount,
                      onChanged: (n) => o.amount = n ?? 0.0,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Padding(
                  padding: const EdgeInsets.only(top: 22.5),
                  child: ToggleSwitch(
                    key: WK.fieldReceiptPaidToggle,
                    checked: o.paid,
                    onChanged: (n) {
                      o.paid = n;
                      state.notify();
                    },
                    content: o.paid ? Text(txt("paid")) : Text(txt("due")),
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InfoLabel(
                    label: "${txt("issuer")}:",
                    child: AutoSuggestBox<String>(
                      key: WK.fieldReceiptIssuer,
                      style: textFieldTextStyle(),
                      decoration: textFieldDecoration(),
                      clearButtonEnabled: false,
                      placeholder: "${txt("issuer")}...",
                      controller: issuerController,
                      noResultsFoundBuilder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(txt("noSuggestions")),
                      ),
                      onChanged: (text, reason) {
                        o.issuer = text;
                        String? phoneNumber = expenses.getPhoneNumber(text);
                        if (phoneNumber != null) {
                          issuerPhoneController.text = phoneNumber;
                          o.phoneNumber = phoneNumber;
                        }
                        state.notify();
                      },
                      items: expenses.allIssuers
                          .map((name) => AutoSuggestBoxItem<String>(value: name, label: name))
                          .toList(),
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
                      controller: issuerPhoneController,
                      noResultsFoundBuilder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(txt("noSuggestions")),
                      ),
                      onChanged: (text, reason) {
                        o.phoneNumber = text;
                        state.notify();
                      },
                      trailingIcon: CallIconButton(phoneNumber: o.phoneNumber),
                      items: expenses.allPhones.map((pn) => AutoSuggestBoxItem<String>(value: pn, label: pn)).toList(),
                    ),
                  ),
                ),
              ],
            ),
            InfoLabel(
              label: "${txt("receiptTags")}:",
              isHeader: true,
              child: TagInputWidget(
                key: WK.fieldReceiptTags,
                suggestions: expenses.allTags.map((t) => TagInputItem(value: t, label: t)).toList(),
                onChanged: (tags) {
                  pages.openExpense.tags = List<String>.from(tags.map((e) => e.value).where((e) => e != null));
                },
                initialValue: pages.openExpense.tags.map((e) => TagInputItem(value: e, label: e)).toList(),
                strict: false,
                limit: 9999,
                placeholder: "${txt("receiptTags")}...",
              ),
            ),
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
