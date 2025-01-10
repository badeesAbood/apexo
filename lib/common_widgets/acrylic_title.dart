import 'package:apexo/services/launch.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/utils/imgs.dart';
import 'package:apexo/utils/que.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../core/model.dart';
import '../utils/get_deterministic_item.dart';
import '../utils/colors_without_yellow.dart';

class AcrylicTitle extends StatelessWidget {
  final Model item;
  final double radius;
  final double maxWidth;
  final IconData? icon;
  final Color? predefinedColor;
  const AcrylicTitle(
      {super.key, required this.item, this.radius = 15, this.maxWidth = 130.0, this.icon, this.predefinedColor});

  @override
  Widget build(BuildContext context) {
    final Color color = predefinedColor ??
        (item.archived == true
            ? Colors.grey.withValues(alpha: 0.2)
            : getDeterministicItem(colorsWithoutYellow, (item.title)));
    return SizedBox(
      width: 200,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(1),
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(100), boxShadow: kElevationToShadow[1]),
          child: FutureBuilder(
              future: item.avatar != null
                  ? (launch.isDemo
                      ? demoAvatarRequestQue.add(() => getImage(item.id, item.avatar!))
                      : getImage(item.id, item.avatar!))
                  : null,
              builder: (context, snapshot) {
                if (item.title.isEmpty) {
                  item.title = " ";
                }
                return CircleAvatar(
                  key: Key(item.id),
                  radius: radius,
                  backgroundColor: color,
                  backgroundImage: (snapshot.data != null) ? snapshot.data : null,
                  child: item.archived == true
                      ? Icon(FluentIcons.archive, size: radius)
                      : snapshot.data == null
                          ? icon == null
                              ? Txt(item.title.substring(0, 1))
                              : Icon(icon, size: radius)
                          : null,
                );
              }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(1.5, 5, 10, 5),
          child: Acrylic(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            luminosityAlpha: 0.3,
            child: Container(
              constraints: BoxConstraints(minWidth: maxWidth < 100 ? maxWidth : 100, maxWidth: maxWidth),
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
              child: Txt(
                item.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        )
      ]),
    );
  }
}
