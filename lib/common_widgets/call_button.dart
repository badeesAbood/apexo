import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class CallIconButton extends StatelessWidget {
  const CallIconButton({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;
  @override
  Widget build(context) {
    return phoneNumber.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.all(5.0),
            child: IconButton(
              icon: const Icon(FluentIcons.phone),
              onPressed: () {
                launchUrl(Uri.parse('tel:$phoneNumber'));
              },
              style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green.withValues(alpha: 0.1))),
            ),
          )
        : const SizedBox();
  }
}
