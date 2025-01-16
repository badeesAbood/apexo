import 'package:apexo/common_widgets/dialogs/dialog_styling.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:fluent_ui/fluent_ui.dart';

void showLoadingBlockingDialog(BuildContext context, String text) {
  showDialog(
      barrierDismissible: false,
      dismissWithEsc: false,
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Txt(text)]),
          content: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [ProgressRing()]),
          style: dialogStyling(context, false),
        );
      });
}
