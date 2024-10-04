import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/widgets/archive_toggle.dart';
import 'package:apexo/pages/widgets/date_time_picker.dart';
import 'package:apexo/pages/widgets/operators_picker.dart';
import 'package:apexo/pages/widgets/patient_picker.dart';
import 'package:apexo/state/stores/labworks/labwork_model.dart';
import 'package:apexo/state/stores/labworks/labworks_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/archive_button.dart';
import "widgets/datatable.dart";
import "widgets/tabbed_modal.dart";

class LabworksPage extends ObservingWidget {
  const LabworksPage({super.key});

  @override
  getObservableState() {
    return [labworks.observableObject];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: DataTable<Labwork>(
        items: labworks.present,
        actions: [
          DataTableAction(
            callback: (_) => openSingleLabwork(
              context: context,
              json: {},
              title: "New labwork",
              onSave: labworks.add,
              editing: false,
            ),
            icon: FluentIcons.manufacturing,
            title: "Add new",
          ),
          DataTableAction(
            callback: (ids) {
              for (var id in ids) {
                labworks.archive(id);
              }
            },
            icon: FluentIcons.archive,
            title: "Archive Selected",
          )
        ],
        furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: labworks.notify)],
        onSelect: (item) => {
          openSingleLabwork(
              context: context, json: item.toJson(), title: "Labwork", onSave: labworks.modify, editing: true)
        },
      ),
    );
  }
}

openSingleLabwork({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Labwork) onSave,
  required bool editing,
}) {
  pages.openLabwork = Labwork.fromJson(json);
  List<TabAction> actions = [
    TabAction(
      text: "Save",
      icon: FluentIcons.save,
      callback: (_) {
        onSave(pages.openLabwork);
        return true;
      },
    )
  ];
  if (editing) actions.add(archiveButton(pages.openLabwork, labworks));
  TextEditingController labNameController = TextEditingController(text: pages.openLabwork.lab);
  TextEditingController labPhoneController = TextEditingController(text: pages.openLabwork.phoneNumber);

  showTabbedModal(context: context, tabs: [
    TabbedModal(
      title: title,
      icon: FluentIcons.manufacturing,
      closable: true,
      spacing: 10,
      content: (state) => [
        InfoLabel(
          label: "Labwork title:",
          child: CupertinoTextField(
              controller: TextEditingController(text: pages.openLabwork.title),
              placeholder: "labwork title",
              onChanged: (val) {
                pages.openLabwork.title = val;
              }),
        ),
        InfoLabel(
          label: "Date:",
          child: DateTimePicker(value: pages.openLabwork.date, onChange: (d) => pages.openLabwork.date = d),
        ),
        InfoLabel(
          label: "Patient:",
          child: PatientPicker(
              value: pages.openLabwork.patientID,
              onChanged: (id) {
                pages.openLabwork.patientID = id;
                state.notify();
              }),
        ),
        InfoLabel(
          label: "Operators:",
          child: OperatorsPicker(
              value: pages.openLabwork.operatorsIDs,
              onChanged: (ids) {
                pages.openLabwork.operatorsIDs = ids;
                state.notify();
              }),
        ),
        InfoLabel(
          label: "Order notes:",
          child: CupertinoTextField(
            controller: TextEditingController(text: pages.openLabwork.note),
            placeholder: "order notes",
            onChanged: (val) {
              pages.openLabwork.note = val;
            },
            maxLines: null,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: InfoLabel(
                label: "Price:",
                child: NumberBox(
                  style: textFieldTextStyle(),
                  clearButton: false,
                  mode: SpinButtonPlacementMode.inline,
                  value: pages.openLabwork.price,
                  onChanged: (n) => pages.openLabwork.price = n ?? 0.0,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Padding(
              padding: const EdgeInsets.only(top: 22.5),
              child: ToggleSwitch(
                checked: pages.openLabwork.paid,
                onChanged: (n) {
                  pages.openLabwork.paid = n;
                  state.notify();
                },
                content: pages.openLabwork.paid ? Text("Paid") : Text("Not paid"),
              ),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: InfoLabel(
                label: "Laboratory:",
                child: AutoSuggestBox<String>(
                  style: textFieldTextStyle(),
                  decoration: textFieldDecoration(),
                  clearButtonEnabled: false,
                  placeholder: "Laboratory name",
                  controller: labNameController,
                  noResultsFoundBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No suggestions"),
                  ),
                  onChanged: (text, reason) {
                    pages.openLabwork.lab = text;
                    String? phoneNumber = labworks.getPhoneNumber(text);
                    if (phoneNumber != null) {
                      labPhoneController.text = phoneNumber;
                      pages.openLabwork.phoneNumber = phoneNumber;
                    }
                    state.notify();
                  },
                  items: labworks.allLabs.map((name) => AutoSuggestBoxItem<String>(value: name, label: name)).toList(),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: InfoLabel(
                label: "Phone:",
                child: AutoSuggestBox<String>(
                  style: textFieldTextStyle(),
                  decoration: textFieldDecoration(),
                  clearButtonEnabled: false,
                  placeholder: "Phone number",
                  controller: labPhoneController,
                  noResultsFoundBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No suggestions"),
                  ),
                  onChanged: (text, reason) {
                    pages.openLabwork.phoneNumber = text;
                    state.notify();
                  },
                  items: labworks.allPhones.map((pn) => AutoSuggestBoxItem<String>(value: pn, label: pn)).toList(),
                ),
              ),
            ),
          ],
        )
      ],
      actions: actions,
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
