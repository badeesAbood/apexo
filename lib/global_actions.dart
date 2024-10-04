import 'package:fluent_ui/fluent_ui.dart';
import './state/state.dart';
import 'backend/observable/observable.dart';

class GlobalAction {
  String tooltip;
  IconData iconData;
  void Function()? onPressed;
  Color activeColor;
  bool? hidden;
  bool? disabled;
  bool? processing;
  bool? animate;
  String? badge;
  GlobalAction({
    required this.tooltip,
    required this.iconData,
    required this.onPressed,
    required this.activeColor,
    this.hidden,
    this.disabled,
    this.processing,
    this.animate,
    this.badge,
  });
}

class GlobalActions extends ObservableObject {
  Map<String, void Function()> syncCallbacks = {};
  Map<String, void Function()> reconnectCallbacks = {};

  List<GlobalAction> get actions {
    return [
      GlobalAction(
        tooltip: "Synchronize",
        iconData: FluentIcons.sync,
        onPressed: () async {
          await state.activate(state.dbBranchUrl, state.token, true);
          for (var callback in syncCallbacks.values) {
            callback();
          }
          await state.downloadImgs();
        },
        badge: state.isSyncing > 0 ? "${state.isSyncing}" : syncCallbacks.length.toString(),
        disabled: (state.isOnline == false || state.isSyncing > 0 || state.proceededOffline),
        processing: state.isSyncing > 0 || state.loadingIndicator.isNotEmpty,
        animate: true,
        activeColor: Colors.blue,
      ),
      GlobalAction(
        tooltip: "Reconnect",
        iconData: (state.isOnline && !state.proceededOffline) ? FluentIcons.streaming : FluentIcons.streaming_off,
        onPressed: () async {
          await state.activate(state.dbBranchUrl, state.token, true);
          for (var callback in reconnectCallbacks.values) {
            callback();
          }
        },
        disabled: (state.isOnline && !state.proceededOffline),
        processing: (state.isOnline && !state.proceededOffline),
        animate: false,
        activeColor: Colors.teal,
      ),
    ];
  }
}

final GlobalActions globalActions = GlobalActions();
