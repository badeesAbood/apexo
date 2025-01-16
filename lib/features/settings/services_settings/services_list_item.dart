import 'package:apexo/core/model.dart';
import 'package:apexo/common_widgets/item_title.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ServicesListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget trailingText;
  const ServicesListItem({
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
          color: FluentTheme.of(context).menuColor,
          child: ListTile(
            title: ItemTitle(
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
