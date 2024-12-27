import 'package:apexo/i18/en.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// ignore: must_be_immutable
class _Sheet extends StatefulWidget {
  List<TabbedModal> tabs;
  Function? onSave;
  Function? onContinue;
  Function? onArchive;
  Function? onRestore;
  int? initiallySelected;
  _Sheet(this.tabs, this.onSave, this.onContinue, this.onArchive, this.onRestore, this.initiallySelected, {super.key});

  @override
  State<StatefulWidget> createState() => SheetState();
}

class SheetState extends State<_Sheet> {
  int selectedTab = 0;
  bool progress = false;

  startProgress() => mounted ? setState(() => progress = true) : null;
  endProgress() => mounted ? setState(() => progress = false) : null;

  void notify() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    selectedTab = widget.initiallySelected ?? 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        alignment: AlignmentDirectional.bottomEnd,
        width: 350,
        margin: const EdgeInsets.fromLTRB(10, 47, 10, 10),
        child: Column(
          children: [
            Expanded(
              child: TabView(
                  currentIndex: selectedTab,
                  tabWidthBehavior: TabWidthBehavior.compact,
                  maxTabWidth: 80,
                  onChanged: (index) {
                    setState(() {
                      selectedTab = index;
                    });
                  },
                  tabs: widget.tabs
                      .map((tab) => Tab(
                            text: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tab.title),
                                if (tab.headerToggle != null) ...[
                                  const SizedBox(width: 10),
                                  tab.headerToggle!(this),
                                ]
                              ],
                            ),
                            icon: Icon(key: Key("${tab.title}_icon"), tab.icon),
                            onClosed: () {
                              Navigator.pop(context);
                            },
                            closeIcon: (tab.closable && widget.tabs.indexOf(tab) == selectedTab)
                                ? const Icon(key: WK.closeModal, FluentIcons.clear)
                                : null,
                            backgroundColor: const Color.fromARGB(255, 225, 225, 225),
                            selectedBackgroundColor: const Color.fromARGB(255, 245, 245, 245),
                            body: Container(
                              decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
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
            ),
            Acrylic(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(5), bottomLeft: Radius.circular(5)),
              ),
              elevation: 50,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: progress
                    ? const ProgressBar()
                    : SizedBox(
                        width: 350,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            selectedTab != 0
                                ? IconButton(
                                    key: WK.tabbedModalBack,
                                    icon: Icon(locale.s.$direction == Direction.ltr
                                        ? FluentIcons.chevron_left
                                        : FluentIcons.chevron_right),
                                    onPressed: () => setState(() => selectedTab--),
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.4))),
                                  )
                                : const SizedBox(width: 26),
                            FilledButton(
                              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                              style: const ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(Colors.warningPrimaryColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(FluentIcons.cancel),
                                  const SizedBox(width: 5),
                                  Text(txt("cancel"))
                                ],
                              ),
                            ),
                            if (widget.onArchive != null)
                              FilledButton(
                                onPressed: () {
                                  widget.onArchive!();
                                  Navigator.of(context, rootNavigator: true).pop();
                                },
                                style: const ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(Colors.grey),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(FluentIcons.archive),
                                    const SizedBox(width: 5),
                                    Text(txt("archive"))
                                  ],
                                ),
                              ),
                            if (widget.onRestore != null)
                              FilledButton(
                                onPressed: () {
                                  widget.onRestore!();
                                  Navigator.of(context, rootNavigator: true).pop();
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(Colors.teal),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(FluentIcons.undo),
                                    const SizedBox(width: 5),
                                    Text(txt("restore"))
                                  ],
                                ),
                              ),
                            if (widget.onSave != null)
                              FilledButton(
                                child: Row(
                                  children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Text(txt("save"))],
                                ),
                                onPressed: () {
                                  widget.onSave!();
                                  Navigator.of(context, rootNavigator: true).pop();
                                },
                              ),
                            if (widget.onContinue != null)
                              FilledButton(
                                child: Row(
                                  children: [
                                    locale.s.$direction == Direction.ltr
                                        ? const Icon(FluentIcons.forward)
                                        : const Icon(FluentIcons.back),
                                    const SizedBox(width: 5),
                                    Text(txt("continue"))
                                  ],
                                ),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                  widget.onContinue!();
                                },
                              ),
                            widget.tabs.length - 1 > selectedTab
                                ? IconButton(
                                    key: WK.tabbedModalNext,
                                    icon: Icon(locale.s.$direction == Direction.ltr
                                        ? FluentIcons.chevron_right
                                        : FluentIcons.chevron_left),
                                    onPressed: () => setState(() => selectedTab++),
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.4))),
                                  )
                                : const SizedBox(width: 26),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Container _buildActions(TabbedModal tab, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 255, 255), boxShadow: [
        BoxShadow(color: Colors.grey.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, -2))
      ]),
      child: Row(
        children: [
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ...tab.actions.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: FilledButton(
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(progress ? Colors.grey.withValues(alpha: 0.4) : action.color)),
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
          ),
        ],
      ),
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
  Function()? onSave,
  Function()? onContinue,
  Function()? onArchive,
  Function()? onRestore,
  int? initiallySelected,
  Key? key,
}) async {
  assert(debugCheckHasMediaQuery(context));
  await Navigator.of(context, rootNavigator: true).push(ModalSheetRoute(
    builder: (_) => _Sheet(tabs, onSave, onContinue, onArchive, onRestore, initiallySelected, key: key),
    containerBuilder: (_, animation, child) => ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(builder: (context, constraints) {
        return Container(
          color: const Color.fromARGB(1, 0, 0, 0),
          alignment: AlignmentDirectional.bottomEnd,
          child: child,
        );
      }),
    ),
    expanded: false,
    isDismissible: true,
    enableDrag: true,
  ));
}
