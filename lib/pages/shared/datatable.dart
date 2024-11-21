import 'dart:convert';
import 'dart:math';
import 'package:apexo/i18/index.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import '../../../backend/utils/colors_without_yellow.dart';
import '../../../backend/observable/model.dart';
import 'acrylic_title.dart';

class _SortableItem<Item> {
  String value;
  Item item;
  _SortableItem(this.value, this.item);
}

class DataTableAction {
  void Function(List<String>) callback;
  IconData icon;
  String title;
  DataTableAction({required this.callback, required this.icon, required this.title});
}

class DataTable<Item extends Model> extends StatefulWidget {
  final List<Item> items;
  final List<DataTableAction> actions;
  final void Function(Item) onSelect;
  final List<Widget> furtherActions;

  const DataTable({
    super.key,
    required this.items,
    required this.actions,
    required this.onSelect,
    this.furtherActions = const [],
  });

  @override
  State<StatefulWidget> createState() => DataTableState<Item>();
}

class DataTableState<Item extends Model> extends State<DataTable<Item>> {
  Set<String> checkedIds = {};
  int sortBy = -1;
  int sortDirection = 1;
  int slice = 10;
  TextEditingController searchTerm = TextEditingController();

  /// labels must be cached since this computation would
  /// occur too many times on every rebuild
  List<String>? _labels;
  List<String> get labels {
    return _labels ??= widget.items
        .fold(<String>{}, (labels, item) => labels..addAll((item.labels.keys.toList()))).toList()
      ..sort((a, b) => a.compareTo(b));
    //..removeWhere((label) => label.isEmpty);
  }

  List<String> get nonNullLabels {
    return labels.where((x) => !x.contains("\u200B")).toList();
  }

  String get sortByString {
    if (sortBy < 0) {
      return "title";
    } else {
      return labels[sortBy];
    }
  }

  String get sortDirectionString {
    if (sortDirection == 1) {
      return "Ascend";
    } else {
      return "Descend";
    }
  }

  List<Item> get filteredItems {
    return widget.items.where((item) {
      return item.title.toLowerCase().contains(searchTerm.text.toLowerCase()) ||
          jsonEncode(item.labels.values.toList()).toLowerCase().contains(searchTerm.text);
    }).toList();
  }

  List<Item> get sortedItems {
    List<Item> result = List<Item>.from(filteredItems);
    if (sortBy < 0) {
      result.sort((a, b) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase()) * sortDirection;
      });
    } else {
      final sorted = List<_SortableItem<Item>>.from(result.map((e) {
        return _SortableItem(e.labels[labels[sortBy]] ?? "", e);
      }))
        ..sort((a, b) {
          if (double.tryParse(a.value) != null && double.tryParse(b.value) != null) {
            return double.parse(a.value).compareTo(double.parse(b.value)) * sortDirection;
          } else {
            return a.value.compareTo(b.value) * sortDirection;
          }
        });
      result = sorted.map((e) => e.item).toList();
    }

    return result.sublist(0, min(result.length, slice));
  }

  showMore() {
    setState(() {
      slice = slice + 10;
    });
  }

  setSearchTerm(String value) {
    setState(() {
      searchTerm.text = value;
    });
  }

  itemSelectToggle(Item item, bool? checked) {
    setState(() {
      if (checked == true) {
        checkedIds.add(item.id);
      } else {
        checkedIds.remove(item.id);
      }
    });
  }

  setSortBy(int? index) {
    setState(() {
      sortBy = index ?? -1;
    });
  }

  toggleSortDirection() {
    setState(() {
      sortDirection = sortDirection * -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCommandBar(),
        _buildListController(),
        _buildItemsList(),
      ],
    );
  }

  Expanded _buildItemsList() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            if (filteredItems.isEmpty) _buildNoItemsFound(),
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length > sortedItems.length ? sortedItems.length + 1 : sortedItems.length,
                itemBuilder: (context, index) =>
                    filteredItems.length > sortedItems.length && index == sortedItems.length
                        ? _buildShowMore()
                        : _buildSingleItem(sortedItems[index], checkedIds.contains(sortedItems[index].id)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Center _buildShowMore() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        width: 100,
        height: 60,
        child: FilledButton(
          style: ButtonStyle(
              elevation: const WidgetStatePropertyAll(10),
              backgroundColor: const WidgetStatePropertyAll(Colors.grey),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(200)))),
          onPressed: showMore,
          child: const Icon(FluentIcons.double_chevron_down),
        ),
      ),
    );
  }

  _buildSingleItem(Item item, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Acrylic(
        child: ListTile(
          contentPadding: const EdgeInsets.all(0),
          title: Container(
            margin: const EdgeInsets.fromLTRB(5, 5, 5, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                //_buildCheckBox(isChecked, item),
                const Divider(direction: Axis.vertical, size: 45),
                _buildInnerRow(item),
                const Divider(direction: Axis.vertical, size: 45),
              ],
            ),
          ),
          leading: _buildCheckBox(isChecked, item),
          onPressed: () => widget.onSelect(item),
        ),
      ),
    );
  }

  int getCycledNumber(int num) {
    return (num - 1) % 7;
  }

  Expanded _buildInnerRow(item) {
    var nonEmptyLabels = labels.where((l) => item.labels[l] != null).toList();
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AcrylicTitle(key: Key(item.id), radius: 20, item: item),
              ...nonEmptyLabels
                  .map((l) => _buildLabelPill(l, item, colorsWithoutYellow[getCycledNumber(nonEmptyLabels.indexOf(l))]))
            ],
          ),
        ),
      ),
    );
  }

  _buildCheckBox(bool isChecked, item) {
    return Checkbox(checked: isChecked, onChanged: (checked) => itemSelectToggle(item, checked));
  }

  Padding _buildListController() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildItemsNumIndicator(), _buildSorters()],
      ),
    );
  }

  Row _buildSorters() {
    return Row(
      children: [_buildSortBy(), const SizedBox(width: 3), _buildSortDirectionToggle()],
    );
  }

  IconButton _buildSortDirectionToggle() {
    return IconButton(
      icon: sortDirection > 0 ? const Icon(FluentIcons.sort_up) : const Icon(FluentIcons.sort_down),
      onPressed: toggleSortDirection,
    );
  }

  ComboBox<int> _buildSortBy() {
    return ComboBox<int>(
      items: [
        ComboBoxItem<int>(value: -1, child: Text(txt("byTitle"))),
        ...nonNullLabels
            .map((l) => ComboBoxItem<int>(value: nonNullLabels.indexOf(l), child: Text("${txt("by")} ${txt(l)}")))
      ],
      value: sortBy,
      onChanged: setSortBy,
    );
  }

  Text _buildItemsNumIndicator() {
    return Text(
      "${txt("showing")} ${sortedItems.length}/${filteredItems.length}",
      style: TextStyle(color: Colors.grey.toAccentColor().lightest, fontSize: 11, fontWeight: FontWeight.bold),
    );
  }

  Acrylic _buildCommandBar() {
    return Acrylic(
      tint: Colors.white.withOpacity(1),
      tintAlpha: 1,
      elevation: 140,
      luminosityAlpha: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Builder(
                builder: (context) => CommandBar(
                  primaryItems: widget.actions
                      .map((a) => CommandBarButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            a.callback(checkedIds.toList());
                          },
                          label: Text(a.title),
                          icon: Icon(a.icon)))
                      .toList(),
                  overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
                ),
              ),
            ),
            const Divider(size: 20, direction: Axis.vertical),
            SizedBox(
              width: 165,
              child: CupertinoTextField(
                controller: searchTerm,
                placeholder: txt("searchPlaceholder"),
                onChanged: setSearchTerm,
              ),
            ),
            ...widget.furtherActions.map((a) => a)
          ],
        ),
      ),
    );
  }

  _buildNoItemsFound() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: InfoBar(
        isIconVisible: true,
        severity: InfoBarSeverity.warning,
        title: Text(txt("noItemsFound")),
      ),
    );
  }

  Widget _buildLabelPill(String l, Item item, [Color? color]) {
    var selected = searchTerm.text.toLowerCase() == item.labels[l]?.toLowerCase();
    color = color ?? colorsWithoutYellow[((labels.indexOf(l) / labels.length) * colorsWithoutYellow.length).floor()];
    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: () {
          if (selected) {
            setSearchTerm("");
          } else {
            setSearchTerm((item.labels[l] ?? "").toLowerCase());
          }
        },
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Acrylic(
              luminosityAlpha: 0.1,
              elevation: 0,
              tint: color,
              shape: RoundedRectangleBorder(
                borderRadius: (selected == false)
                    ? BorderRadius.circular(5)
                    : const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                child: Wrap(
                  children: [
                    Text(
                      (txt(l)),
                      style: TextStyle(
                          fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 11.5, color: color),
                    ),
                    const SizedBox(width: 5),
                    const Divider(direction: Axis.vertical, size: 10),
                    const SizedBox(width: 5),
                    Text(
                      (item.labels[l]) ?? "",
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              Acrylic(
                tint: Colors.grey,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(topRight: Radius.circular(5), bottomRight: Radius.circular(5)),
                ),
                luminosityAlpha: 0.1,
                child: SizedBox(
                  height: 35,
                  child: IconButton(
                    icon: const Icon(FluentIcons.check_mark, size: 10),
                    onPressed: () {
                      setSearchTerm("");
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
