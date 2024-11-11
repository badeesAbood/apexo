import 'package:apexo/backend/observable/model.dart';
import 'package:apexo/pages/widgets/acrylic_title.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SettingsListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget trailingText;
  const SettingsListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Acrylic(
        elevation: 3,
        child: Container(
          color: Colors.white,
          child: ListTile(
            title: AcrylicTitle(
              item: Model.fromJson({"title": title}),
              radius: 1,
              maxWidth: 180,
            ),
            subtitle: Text(subtitle),
            trailing: Column(
              children: [
                trailingText,
                const SizedBox(height: 7),
                Row(
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
