import 'package:apexo/services/archived.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ArchiveToggle extends StatelessWidget {
  final void Function()? notifier;
  const ArchiveToggle({super.key, this.notifier});
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.2,
      child: Tooltip(
        message: txt("showHideArchived"),
        child: StreamBuilder(
            stream: showArchived.stream,
            builder: (context, _) {
              return Checkbox(
                style: const CheckboxThemeData(
                  uncheckedIconColor: WidgetStatePropertyAll(Colors.grey),
                  icon: FluentIcons.archive,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                ),
                checked: showArchived(),
                onChanged: (checked) {
                  showArchived(checked == true ? true : false);
                  notifier?.call();
                },
              );
            }),
      ),
    );
  }
}
