import 'package:fluent_ui/fluent_ui.dart';

class SwipeDetector extends StatelessWidget {
  final Widget child;
  final void Function() onSwipeLeft;
  final void Function() onSwipeRight;

  const SwipeDetector({
    super.key,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx > 0) {
          onSwipeLeft();
        } else if (details.velocity.pixelsPerSecond.dx < 0) {
          onSwipeRight();
        }
      },
      child: child,
    );
  }
}
