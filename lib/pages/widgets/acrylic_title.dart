import 'package:fluent_ui/fluent_ui.dart';
import '../../backend/observable/model.dart';
import '../../backend/utils/get_deterministic_item.dart';
import '../../backend/utils/colors_without_yellow.dart';

// ignore: must_be_immutable
class AcrylicTitle extends StatelessWidget {
  final Model item;
  final double radius;
  late Color color;
  AcrylicTitle({super.key, required this.item, this.radius = 15}) {
    if (item.title.isEmpty) {
      item.title = " ";
    }
    color =
        item.archived == true ? Colors.grey.withOpacity(0.2) : getDeterministicItem(colorsWithoutYellow, (item.title));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Row(children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color,
          backgroundImage: (item.imgUrl != null && item.imgUrl!.isNotEmpty) ? NetworkImage(item.imgUrl!) : null,
          child: item.archived == true
              ? Icon(FluentIcons.archive, size: radius)
              : item.imgUrl == null
                  ? Text(item.title.substring(0, 1))
                  : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
          child: Acrylic(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            luminosityAlpha: 0.3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 130),
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
              child: Text(
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
