import 'package:fluent_ui/fluent_ui.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// ignore: must_be_immutable
class _Sheet extends StatefulWidget {
  int selectedIndex = 0;
  List<TabbedModal> tabs;
  double height = 500;

  _Sheet(this.tabs);

  @override
  State<StatefulWidget> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        alignment: AlignmentDirectional.bottomEnd,
        width: 350,
        height: widget.tabs[widget.selectedIndex].content().length * 95 + 100,
        margin: const EdgeInsets.fromLTRB(12, 40, 12, 12),
        child: TabView(
            currentIndex: widget.selectedIndex,
            tabWidthBehavior: TabWidthBehavior.compact,
            onChanged: (index) {
              setState(() {
                widget.selectedIndex = index;
              });
            },
            tabs: widget.tabs
                .map((tab) => Tab(
                      text: Text(tab.title),
                      icon: Icon(tab.icon),
                      onClosed: () {
                        Navigator.pop(context);
                      },
                      closeIcon: (tab.closable && widget.tabs.indexOf(tab) == widget.selectedIndex)
                          ? const Icon(FluentIcons.clear)
                          : null,
                      backgroundColor: const Color.fromARGB(255, 194, 194, 194),
                      selectedBackgroundColor: const Color.fromARGB(255, 245, 245, 245),
                      body: Container(
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            color: Color.fromARGB(255, 245, 245, 245)),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: tab
                                    .content()
                                    .map((e) => Padding(padding: const EdgeInsets.only(bottom: 20), child: e))
                                    .toList(),
                              ),
                            ),
                            if (tab.actions.isNotEmpty) _buildActions(tab, context)
                          ],
                        ),
                      ),
                    ))
                .toList()),
      );
    });
  }

  Container _buildActions(TabbedModal tab, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
          color: const Color.fromARGB(255, 240, 240, 240)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ...tab.actions.map((action) => Padding(
                padding: const EdgeInsets.only(left: 5),
                child: FilledButton(
                  style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(action.color)),
                  onPressed: () {
                    if (action.callback()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Row(
                    children: [Icon(action.icon), const SizedBox(width: 10), Text(action.text)],
                  ),
                ),
              ))
        ]),
      ),
    );
  }
}

class TabAction {
  String text;
  IconData icon;
  Color? color;
  bool Function() callback;
  TabAction({required this.text, required this.callback, required this.icon, this.color});
}

class TabbedModal {
  String title;
  IconData icon;
  bool closable;
  List<Widget> Function() content;
  List<TabAction> actions;
  TabbedModal({
    required this.title,
    required this.icon,
    required this.closable,
    required this.content,
    this.actions = const [],
  });
}

void showTabbedModal({
  required BuildContext context,
  required List<TabbedModal> tabs,
  int initiallySelected = 0,
}) async {
  assert(debugCheckHasMediaQuery(context));
  await Navigator.of(context, rootNavigator: true).push(ModalSheetRoute(
    builder: (_) => _Sheet(tabs),
    containerBuilder: (_, animation, child) => ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          child: Container(
            color: const Color.fromARGB(1, 0, 0, 0),
            alignment: AlignmentDirectional.bottomEnd,
            child: GestureDetector(
              onTap: () {
                // leave it empty
              },
              child: child,
            ),
          ),
        );
      }),
    ),
    expanded: false,
    isDismissible: true,
    enableDrag: true,
  ));
}
