import 'dart:convert';
import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../backend/utils/colors_without_yellow.dart';
import '../../../backend/observable/model.dart';
import '../../../backend/utils/get_deterministic_item.dart';
import './acrylic_title.dart';

class DataTableAction {
  void Function(List<String>) callback;
  IconData icon;
  String title;
  DataTableAction({required this.callback, required this.icon, required this.title});
}

class DataTable<Item extends Model> extends StatefulWidget {
  final List<Item> items;
  final List<String> labels;
  final List<DataTableAction> actions;
  final void Function(Item) onSelect;
  final List<Widget> furtherActions;

  const DataTable({
    super.key,
    required this.items,
    required this.labels,
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

  String get sortByString {
    if (sortBy < 0) {
      return "title";
    } else {
      return widget.labels[sortBy];
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
    List<Item> sortedItems = List.from(filteredItems);
    if (sortBy < 0) {
      sortedItems.sort((a, b) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase()) * sortDirection;
      });
    } else {
      sortedItems.sort((a, b) {
        var aValue = a.labels[widget.labels[sortBy]] ?? "";
        var bValue = b.labels[widget.labels[sortBy]] ?? "";

        if (double.tryParse(aValue) != null && double.tryParse(bValue) != null) {
          return double.parse(aValue).compareTo(double.parse(bValue)) * sortDirection;
        } else {
          return aValue.compareTo(bValue) * sortDirection;
        }
      });
    }

    return sortedItems.sublist(0, min(sortedItems.length, slice));
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

                // [
                //   if (filteredItems.isEmpty) _buildNoItemsFound(),
                //   ...sortedItems.map((item) {
                //     bool isChecked = checkedIds.contains(item.id);
                //     return _buildSingleItem(item, isChecked);
                //   }),
                //   if (sortedItems.length < filteredItems.length)

                // ],
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
          contentPadding: EdgeInsets.all(0),
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

  Expanded _buildInnerRow(item) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AcrylicTitle(radius: 20, item: item),
              ...widget.labels.where((l) => item.labels[l] != null).map((l) => _buildLabelPill(l, item))
            ],
          ),
        ),
      ),
    );
  }

  _buildCheckBox(bool isChecked, item) {
    return Checkbox(checked: isChecked, onChanged: (checked) => itemSelectToggle(item, checked));
  }

  BoxDecoration _itemBorder(item, bool isChecked) {
    return BoxDecoration(
      gradient: LinearGradient(colors: [
        getDeterministicItem(colorsWithoutYellow, item.title).withOpacity(0.1),
        Colors.white.withOpacity(0.01),
      ]),
      border: Border.all(
        color: isChecked ? Colors.blue : Colors.transparent,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(300),
    );
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
        const ComboBoxItem<int>(value: -1, child: Text("By title")),
        ...widget.labels.map((l) => ComboBoxItem<int>(value: widget.labels.indexOf(l), child: Text("By $l")))
      ],
      value: sortBy,
      onChanged: setSortBy,
    );
  }

  Text _buildItemsNumIndicator() {
    return Text(
      "Showing ${sortedItems.length}/${filteredItems.length}",
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
              child: TextBox(
                controller: searchTerm,
                placeholder: "search",
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
    return const Padding(
      padding: EdgeInsets.all(15),
      child: InfoBar(
        isIconVisible: true,
        severity: InfoBarSeverity.warning,
        title: Text("No items found"),
      ),
    );
  }

  Widget _buildArchiveLabel() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        margin: const EdgeInsets.fromLTRB(10, 25, 0, 0),
        decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(119, 50, 49, 48)),
            color: Colors.grey,
            borderRadius: BorderRadius.circular(20)),
        child: const Text(
          "Archive",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLabelPill(String l, Item item) {
    var selected = searchTerm.text.toLowerCase() == item.labels[l]?.toLowerCase();
    var color =
        colorsWithoutYellow[((widget.labels.indexOf(l) / widget.labels.length) * colorsWithoutYellow.length).floor()];
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
                      "$l: ",
                      style: TextStyle(
                          fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 11.5, color: color),
                    ),
                    const SizedBox(width: 5),
                    const Divider(direction: Axis.vertical, size: 10),
                    const SizedBox(width: 5),
                    Text(
                      item.labels[l] ?? "",
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
