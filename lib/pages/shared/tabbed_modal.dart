import 'package:fluent_ui/fluent_ui.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// ignore: must_be_immutable
class _Sheet extends StatefulWidget {
  List<TabbedModal> tabs;
  double height = 500;

  _Sheet(this.tabs);

  @override
  State<StatefulWidget> createState() => SheetState();
}

class SheetState extends State<_Sheet> {
  int selectedTab = 0;
  bool progress = false;

  startProgress() => mounted ? setState(() => progress = true) : null;
  endProgress() => mounted ? setState(() => progress = false) : null;

  notify() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        alignment: AlignmentDirectional.bottomEnd,
        width: 350,
        margin: const EdgeInsets.fromLTRB(12, 40, 12, 12),
        child: TabView(
            currentIndex: selectedTab,
            tabWidthBehavior: TabWidthBehavior.compact,
            onChanged: (index) {
              setState(() {
                selectedTab = index;
              });
            },
            tabs: widget.tabs
                .map((tab) => Tab(
                      text: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tab.title),
                          if (tab.headerToggle != null) ...[
                            const SizedBox(width: 10),
                            tab.headerToggle!(this),
                          ]
                        ],
                      ),
                      icon: Icon(tab.icon),
                      onClosed: () {
                        Navigator.pop(context);
                      },
                      closeIcon: (tab.closable && widget.tabs.indexOf(tab) == selectedTab)
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
                                padding: EdgeInsets.all(tab.padding),
                                children: tab
                                    .content(this)
                                    .map((e) => Padding(padding: EdgeInsets.only(bottom: tab.spacing), child: e))
                                    .toList(),
                              ),
                            ),
                            if (tab.actions.isNotEmpty) _buildActions(tab, context),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
          color: const Color.fromARGB(255, 255, 255, 255),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, -2))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        progress ? const ProgressBar() : const SizedBox(),
        ...tab.actions.map((action) => Padding(
              padding: const EdgeInsets.only(left: 5),
              child: FilledButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(progress ? Colors.grey.withOpacity(0.4) : action.color)),
                onPressed: () {
                  if (progress) return;
                  if (action.callback(this)) {
                    Navigator.pop(context);
                  }
                },
                child: Row(
                  children: [Icon(action.icon), const SizedBox(width: 10), Text(action.text)],
                ),
              ),
            ))
      ]),
    );
  }
}

class TabAction {
  String text;
  IconData icon;
  Color? color;
  bool Function(SheetState) callback;
  TabAction({required this.text, required this.callback, required this.icon, this.color});
}

class TabbedModal {
  String title;
  IconData icon;
  bool closable;
  List<Widget> Function(SheetState) content;
  List<TabAction> actions;
  double spacing;
  double padding;
  Widget Function(SheetState)? headerToggle;

  TabbedModal({
    required this.title,
    required this.icon,
    required this.closable,
    required this.content,
    this.headerToggle,
    this.spacing = 20,
    this.padding = 20,
    this.actions = const [],
  });
}

void showTabbedModal({
  required BuildContext context,
  required List<TabbedModal> tabs,
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
