import 'dart:async';
import 'dart:convert';
import 'package:apexo/app/routes.dart';
import 'package:apexo/common_widgets/acrylic_title.dart';
import 'package:apexo/core/model.dart';
import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

class PanelScreen extends StatefulWidget {
  final double height;
  final Panel panel;
  const PanelScreen({
    required this.panel,
    this.height = 500,
    super.key,
  });

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  late bool isNew;
  final FocusNode focusNode = FocusNode();
  final panelSwitchController = FlyoutController();
  late Timer saveButtonCheckTimer;

  @override
  void dispose() {
    saveButtonCheckTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isNew = widget.panel.store.get(widget.panel.item.id) == null;
    saveButtonCheckTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (jsonEncode(widget.panel.item.toJson()) != widget.panel.savedJson && widget.panel.enableSaveButton() != true) {
        widget.panel.enableSaveButton(true);
      } else if (jsonEncode(widget.panel.item.toJson()) == widget.panel.savedJson &&
          widget.panel.enableSaveButton() != false) {
        widget.panel.enableSaveButton(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: focusNode,
      onKeyEvent: (value) {
        if (value is KeyDownEvent && value.logicalKey == LogicalKeyboardKey.escape && routes.panels().isNotEmpty) {
          routes.goBack();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Acrylic(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          elevation: 120,
          child: MStreamBuilder(
              streams: [locale.selectedLocale.stream, widget.panel.selectedTab.stream],
              builder: (context, snapshot) {
                return Column(
                  key: Key(locale.selectedLocale().toString()),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPanelHeader(),
                    _buildTabsControllers(),
                    _buildTabBody(),
                    if (widget.panel.tabs[widget.panel.selectedTab()].footer != null)
                      widget.panel.tabs[widget.panel.selectedTab()].footer!,
                    _buildBottomControls(),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Expanded _buildTabBody() {
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          color: const Color.fromARGB(255, 250, 250, 250),
          padding: EdgeInsets.all(widget.panel.tabs[widget.panel.selectedTab()].padding.toDouble()),
          constraints: BoxConstraints(
              minHeight: widget.panel.tabs[widget.panel.selectedTab()].footer == null
                  ? widget.height - 161
                  : widget.height - 206),
          child: widget.panel.tabs[widget.panel.selectedTab()].body,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      constraints: const BoxConstraints(minHeight: 50, minWidth: 350),
      child: Acrylic(
        luminosityAlpha: 0.2,
        elevation: 5,
        child: StreamBuilder(
            stream: widget.panel.inProgress.stream,
            builder: (context, snapshot) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                ),
                padding: const EdgeInsets.all(10),
                child: widget.panel.inProgress()
                    ? const Center(child: ProgressBar())
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (isNew == false && widget.panel.item.archived == true) _buildRestoreButton(),
                          if (isNew == false && widget.panel.item.archived != true) _buildArchiveButton(),
                          _buildSaveButton(),
                          _buildCancelButton(),
                        ],
                      ),
              );
            }),
      ),
    );
  }

  Widget _buildCancelButton() {
    return StreamBuilder<bool>(
        stream: widget.panel.enableSaveButton.stream,
        builder: (context, _) {
          return FilledButton(
            onPressed: routes.goBack,
            style: ButtonStyle(
              backgroundColor: widget.panel.enableSaveButton()
                  ? WidgetStatePropertyAll(Colors.orange)
                  : const WidgetStatePropertyAll(Colors.grey),
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.cancel),
                const SizedBox(width: 5),
                Txt(widget.panel.enableSaveButton() ? txt("cancel") : txt("close"))
              ],
            ),
          );
        });
  }

  Widget _buildSaveButton() {
    return StreamBuilder<bool>(
        stream: widget.panel.enableSaveButton.stream,
        builder: (context, _) {
          return FilledButton(
            onPressed: () {
              if (widget.panel.enableSaveButton()) {
                widget.panel.store.set(widget.panel.item);
                widget.panel.savedJson = jsonEncode(widget.panel.item.toJson());
                widget.panel.identifier = widget.panel.item.id;
                if (!widget.panel.result.isCompleted) {
                  widget.panel.result.complete(widget.panel.item);
                }
                setState(() {
                  isNew = false;
                  widget.panel.title = null;
                });
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                  widget.panel.enableSaveButton() ? Colors.blue : Colors.grey.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Txt(txt("save"))],
            ),
          );
        });
  }

  FilledButton _buildArchiveButton() {
    return FilledButton(
      onPressed: () {
        widget.panel.store.archive(widget.panel.item.id);
        routes.goBack();
      },
      style: const ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.grey),
      ),
      child: Row(
        children: [const Icon(FluentIcons.archive), const SizedBox(width: 5), Txt(txt("archive"))],
      ),
    );
  }

  FilledButton _buildRestoreButton() {
    return FilledButton(
      onPressed: () {
        widget.panel.store.unarchive(widget.panel.item.id);
        routes.goBack();
      },
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.teal),
      ),
      child: Row(
        children: [const Icon(FluentIcons.archive_undo), const SizedBox(width: 5), Txt(txt("Restore"))],
      ),
    );
  }

  Acrylic _buildTabsControllers() {
    return Acrylic(
      luminosityAlpha: 0.9,
      elevation: 30,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3, 17, 3, 0),
        child: SizedBox(
          height: 39,
          child: TabView(
            closeButtonVisibility: CloseButtonVisibilityMode.never,
            onChanged: (value) => widget.panel.selectedTab(value),
            currentIndex: widget.panel.selectedTab(),
            showScrollButtons: false,
            shortcutsEnabled: true,
            tabWidthBehavior: TabWidthBehavior.compact,
            header: widget.panel.selectedTab() != 0
                ? IconButton(
                    icon: const Icon(FluentIcons.chevron_left),
                    onPressed: () => widget.panel.selectedTab(widget.panel.selectedTab() - 1),
                  )
                : const SizedBox(width: 25),
            footer:
                widget.panel.selectedTab() < widget.panel.tabs.where((t) => t.onlyIfSaved ? (!isNew) : true).length - 1
                    ? IconButton(
                        icon: const Icon(FluentIcons.chevron_right),
                        onPressed: () => widget.panel.selectedTab(widget.panel.selectedTab() + 1),
                      )
                    : const SizedBox(width: 25),
            tabs: widget.panel.tabs
                .map((e) => Tab(
                      text: Txt(e.title),
                      icon: Icon(e.icon),
                      body: const SizedBox(),
                      disabled: e.onlyIfSaved && isNew,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
      color: Colors.grey.withValues(alpha: 0.1),
      child: StreamBuilder(
          stream: widget.panel.inProgress.stream,
          builder: (context, snapshot) {
            final storeSingularName =
                widget.panel.store.local!.name.substring(0, widget.panel.store.local!.name.length - 1);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 173,
                  child: AcrylicTitle(
                    radius: 13,
                    fontSize: 13,
                    item:
                        widget.panel.title != null ? Model.fromJson({"title": widget.panel.title}) : widget.panel.item,
                    icon: widget.panel.item.archived == true
                        ? FluentIcons.archive
                        : isNew
                            ? FluentIcons.add
                            : FluentIcons.edit,
                    predefinedColor: widget.panel.item.archived == true ? Colors.grey : null,
                  ),
                ),
                Txt(txt(storeSingularName), style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.7))),
                Row(children: [
                  if (routes.panels().length > 1)
                    FlyoutTarget(
                      controller: panelSwitchController,
                      child: IconButton(
                          icon: Row(
                            children: [
                              const Icon(FluentIcons.reopen_pages),
                              const SizedBox(width: 2),
                              Text(
                                routes.panels().length.toString(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          onPressed: openPanelSwitch),
                    ),
                  widget.panel.inProgress()
                      ? const SizedBox(height: 20, width: 20, child: ProgressRing())
                      : IconButton(icon: const Icon(FluentIcons.cancel), onPressed: routes.goBack)
                ])
              ],
            );
          }),
    );
  }

  void openPanelSwitch() {
    panelSwitchController.showFlyout(
      barrierDismissible: false,
      dismissWithEsc: true,
      dismissOnPointerMoveAway: true,
      builder: (context) => MenuFlyout(items: [
        ...([...routes.panels()]..sort((a, b) => b.creationDate - a.creationDate)).map((panel) {
          final singularStoreName = panel.store.local!.name.substring(0, panel.store.local!.name.length - 1);
          return MenuFlyoutItem(
            selected: panel == widget.panel,
            leading: Icon(panel.icon),
            trailing: panel.inProgress()
                ? const SizedBox(height: 20, width: 20, child: ProgressRing())
                : Icon(panel.store.get(panel.item.id) == null ? FluentIcons.add : FluentIcons.edit),
            text: Txt("${txt(singularStoreName)}: ${panel.title ?? panel.item.title}",
                style: TextStyle(fontWeight: panel == widget.panel ? FontWeight.w500 : null)),
            onPressed: () => routes.bringPanelToFront(routes.panels().indexOf(panel)),
            closeAfterClick: true,
          );
        })
      ]),
    );
  }
}
