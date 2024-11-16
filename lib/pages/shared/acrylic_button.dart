import 'package:fluent_ui/fluent_ui.dart';

class AcrylicButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onPressed;
  final double elevation;

  const AcrylicButton({super.key, required this.icon, required this.text, required this.onPressed, this.elevation = 1});
  @override
  Widget build(BuildContext context) {
    return Acrylic(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      elevation: elevation,
      child: IconButton(
          icon: Row(
            children: [Icon(icon), const SizedBox(width: 5), Text(text)],
          ),
          onPressed: onPressed),
    );
  }
}
