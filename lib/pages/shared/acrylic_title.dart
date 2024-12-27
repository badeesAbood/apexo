import 'package:apexo/backend/utils/imgs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../backend/observable/model.dart';
import '../../backend/utils/get_deterministic_item.dart';
import '../../backend/utils/colors_without_yellow.dart';

class AcrylicTitle extends StatefulWidget {
  final Model item;
  final double radius;
  final double maxWidth;
  const AcrylicTitle({super.key, required this.item, this.radius = 15, this.maxWidth = 130.0});

  @override
  State<AcrylicTitle> createState() => _AcrylicTitleState();
}

class _AcrylicTitleState extends State<AcrylicTitle> {
  @override
  Widget build(BuildContext context) {
    final Color color = (widget.item.archived == true
        ? Colors.grey.withValues(alpha: 0.2)
        : getDeterministicItem(colorsWithoutYellow, (widget.item.title)));
    return SizedBox(
      width: 200,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(1),
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(100), boxShadow: kElevationToShadow[1]),
          child: FutureBuilder(
              future: widget.item.avatar != null ? getImage(widget.item.id, widget.item.avatar!) : null,
              builder: (context, snapshot) {
                if (widget.item.title.isEmpty) {
                  widget.item.title = " ";
                }
                return CircleAvatar(
                  key: Key(widget.item.id),
                  radius: widget.radius,
                  backgroundColor: color,
                  backgroundImage: (snapshot.data != null) ? snapshot.data : null,
                  child: widget.item.archived == true
                      ? Icon(FluentIcons.archive, size: widget.radius)
                      : snapshot.data == null
                          ? Text(widget.item.title.substring(0, 1))
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
              constraints:
                  BoxConstraints(minWidth: widget.maxWidth < 100 ? widget.maxWidth : 100, maxWidth: widget.maxWidth),
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
              child: Text(
                widget.item.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        )
      ]),
    );
  }
}
