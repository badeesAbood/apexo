import 'dart:convert';
import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/backend/utils/hash.dart';
import 'package:apexo/backend/utils/imgs.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/settings/window_backups.dart';
import 'package:apexo/pages/shared/tabbed_modal.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

// ignore: must_be_immutable
class ImportDialog extends ObservingWidget {
  SheetState state;

  ImportDialog({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const SizedBox(),
      style: dialogStyling(false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoBar(
            title: Text("Importing photos from link"),
            content: Text(
              "Use this form to import photos from share links, like google photos, or any accessible web page that contains photos you'd like to add to this appointment.",
            ),
          ),
          SizedBox(height: 10),
          if (importResult().length > 1)
            InfoBar(
              title: Text("Error"),
              content: Text(importResult()),
              severity: InfoBarSeverity.error,
            ),
          SizedBox(height: 10),
          InfoLabel(
            label: "Link",
            child: CupertinoTextField(
                controller: importPhotosFromLinkController, placeholder: "Enter a URL that contains photos"),
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
              children: [Icon(FluentIcons.save), SizedBox(width: 5), Text("Import")]),
          onPressed: () async {
            importResult(".");
            state.notify();
            List<String> res;
            try {
              final response = await get(
                  Uri.parse('https://imgs.apexo.app/?url=${Uri.encodeComponent(importPhotosFromLinkController.text)}'));
              if (response.statusCode != 200) {
                throw Exception(response.body);
              } else {
                importResult("");
                res = List<String>.from(jsonDecode(response.body));
              }
            } catch (e) {
              importResult(e.toString());
              state.notify();
              return;
            }
            if (context.mounted) Navigator.pop(context);
            state.startProgress();
            for (var imgLink in res) {
              // copy
              final imgExtension = (await getImageExtensionFromURL(imgLink)) ?? ".jpg";
              final imgName = simpleHash(imgLink) + imgExtension;
              final imgFile = await saveImageFromUrl(imgLink, imgName);
              // upload images
              await appointments.uploadImgs(pages.openAppointment.id, [imgFile.path]);
              // update the model only if it didn't exist before
              if (pages.openAppointment.imgs.contains(imgName) == false) {
                pages.openAppointment.imgs.add(imgName);
                appointments.set(pages.openAppointment);
              }
            }
            state.endProgress();
          },
        ),
      ],
    );
  }

  @override
  List<ObservableBase> getObservableState() {
    importPhotosFromLinkController.text = "";
    importResult("");
    return [importResult];
  }
}

final importPhotosFromLinkController = TextEditingController();
final importResult = ObservableState("");
