import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/state/state.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ArchiveToggle extends ObservingWidget {
  final void Function()? notifier;
  const ArchiveToggle({super.key, this.notifier});
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.2,
      child: Tooltip(
        message: txt("showHideArchived"),
        child: Checkbox(
          style: const CheckboxThemeData(
            uncheckedIconColor: WidgetStatePropertyAll(Colors.grey),
            icon: FluentIcons.archive,
            margin: EdgeInsets.symmetric(horizontal: 3),
          ),
          checked: state.showArchived,
          onChanged: (checked) {
            state.showArchivedChanged(checked);
            notifier?.call();
          },
        ),
      ),
    );
  }

  @override
  getObservableState() {
    return [state];
  }
}
