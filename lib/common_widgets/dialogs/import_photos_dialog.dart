import 'dart:convert';
import 'package:apexo/app/routes.dart';
import 'package:apexo/common_widgets/dialogs/close_dialog_button.dart';
import 'package:apexo/common_widgets/dialogs/dialog_styling.dart';
import 'package:apexo/core/observable.dart';
import 'package:apexo/features/appointments/appointment_model.dart';
import 'package:apexo/utils/imgs.dart';
import 'package:apexo/utils/logger.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

// ignore: must_be_immutable
class ImportDialog extends StatelessWidget {
  Panel<Appointment> panel;

  ImportDialog({super.key, required this.panel});

  final importPhotosFromLinkController = TextEditingController();
  final importResult = ObservableState("");

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: importResult.stream,
        builder: (context, _) {
          return ContentDialog(
            title: const SizedBox(),
            style: dialogStyling(false),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoBar(
                  title: Txt(txt("importingPhotosFromLink")),
                  content: Txt(txt("useThisForm")),
                ),
                const SizedBox(height: 10),
                if (importResult().length > 1)
                  InfoBar(
                    title: Txt(txt("error")),
                    content: Txt(importResult()),
                    severity: InfoBarSeverity.error,
                  ),
                const SizedBox(height: 10),
                InfoLabel(
                  label: txt("link"),
                  child: CupertinoTextField(controller: importPhotosFromLinkController, placeholder: txt("enterLink")),
                ),
              ],
            ),
            actions: [
              if (importResult().length == 1) const ProgressBar(),
              const CloseButtonInDialog(),
              FilledButton(
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [const Icon(FluentIcons.save), const SizedBox(width: 5), Txt(txt("import"))]),
                onPressed: () async {
                  // cache the id so that if the user opens another appointment
                  // the photos would go to the correct appointment
                  final id = panel.item.id;
                  importResult(".");
                  panel.selectedTab(panel.selectedTab());
                  List<String> res;
                  try {
                    final response = await get(Uri.parse(
                        'https://imgs.apexo.app/?url=${Uri.encodeComponent(importPhotosFromLinkController.text)}'));
                    if (response.statusCode != 200) {
                      throw Exception(response.body);
                    } else {
                      importResult("");
                      res = List<String>.from(jsonDecode(response.body));
                    }
                  } catch (e) {
                    importResult(e.toString());
                    panel.selectedTab(panel.selectedTab());
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                  panel.inProgress(true);
                  try {
                    for (var imgLink in res) {
                      final imgName = await handleNewImage(rowID: id, targetPath: imgLink);
                      if (panel.item.imgs.contains(imgName) == false) {
                        panel.item.imgs.add(imgName);
                        appointments.set(panel.item);
                        panel.savedJson = jsonEncode(panel.item.toJson());
                      }
                      panel.selectedTab(panel.selectedTab());
                    }
                  } catch (e, s) {
                    logger("Error during images importing: $e", s);
                  }
                  panel.inProgress(false);
                  panel.selectedTab(panel.selectedTab());
                },
              ),
            ],
          );
        });
  }
}
