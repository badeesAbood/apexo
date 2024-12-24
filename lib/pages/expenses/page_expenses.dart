import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/expenses/modal_expenses.dart';
import 'package:apexo/pages/shared/archive_selected.dart';
import 'package:apexo/pages/shared/archive_toggle.dart';
import 'package:apexo/pages/shared/datatable.dart';
import 'package:apexo/state/stores/expenses/expenses_model.dart';
import 'package:apexo/state/stores/expenses/expenses_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpensesPage extends ObservingWidget {
  const ExpensesPage({super.key});

  @override
  getObservableState() {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      key: WK.expensesPage,
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          Expanded(
            child: DataTable<Expense>(
              compact: true,
              items: expenses.present.values.toList(),
              actions: [
                DataTableAction(
                  callback: (_) {
                    openSingleReceipt(
                        context: context, json: {}, title: txt("newReceipt"), onSave: expenses.set, editing: false);
                  },
                  icon: FluentIcons.manufacturing,
                  title: txt("add"),
                ),
                archiveSelected(expenses)
              ],
              furtherActions: [const SizedBox(width: 5), ArchiveToggle(notifier: expenses.notify)],
              onSelect: (item) => {
                openSingleReceipt(
                    context: context, json: item.toJson(), title: txt("receipt"), onSave: expenses.set, editing: true)
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
            ),
          ),
        ],
      ),
    );
  }
}
