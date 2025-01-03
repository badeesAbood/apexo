import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/expenses/single_expense_modal.dart';
import 'package:apexo/common_widgets/archive_selected.dart';
import 'package:apexo/common_widgets/archive_toggle.dart';
import 'package:apexo/common_widgets/datatable.dart';
import 'package:apexo/features/expenses/expense_model.dart';
import 'package:apexo/features/expenses/expenses_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.expensesScreen,
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          Expanded(
            child: StreamBuilder(
                stream: expenses.observableObject.stream,
                builder: (context, snapshot) {
                  return DataTable<Expense>(
                    compact: true,
                    items: expenses.present.values.toList(),
                    actions: [
                      DataTableAction(
                        callback: (_) {
                          openSingleReceipt(
                              context: context,
                              json: {},
                              title: txt("newReceipt"),
                              onSave: expenses.set,
                              editing: false);
                        },
                        icon: FluentIcons.bill,
                        title: txt("add"),
                      ),
                      archiveSelected(expenses)
                    ],
                    furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: expenses.notify)],
                    onSelect: (item) => {
                      openSingleReceipt(
                          context: context,
                          json: item.toJson(),
                          title: txt("receipt"),
                          onSave: expenses.set,
                          editing: true)
                    },
                    itemActions: [
                      ItemAction(
                        icon: FluentIcons.phone,
                        title: txt("callIssuer"),
                        callback: (id) {
                          final receipt = expenses.get(id);
                          if (receipt == null) return;
                          launchUrl(Uri.parse('tel:${receipt.phoneNumber}'));
                        },
                      ),
                      ItemAction(
                        icon: FluentIcons.archive,
                        title: txt("archive"),
                        callback: (id) {
                          expenses.archive(id);
                        },
                      ),
                    ],
                    defaultSortDirection: -1,
                    defaultSortingName: "byDate",
                  );
                }),
          ),
        ],
      ),
    );
  }
}
