import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/state/state.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class ProductionTestWindow extends ObservingWidget {
  final testEmailController = TextEditingController(text: state.email);
  ProductionTestWindow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Expander(
        leading: const Icon(FluentIcons.test_case),
        header: const Text("Production tests"),
        contentPadding: const EdgeInsets.all(10),
        content: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoBar(
                title: Text("File storage test"),
                severity: InfoBarSeverity.info,
                content: Text("Use the following button to test whether S3 storage is working properly."),
              ),
              Row(
                children: [
                  FilledButton(
                      child: Text("Test S3 setup"),
                      onPressed: () async {
                        _s3Result(".");
                        try {
                          await state.pb!.settings.testS3();
                        } catch (e) {
                          _s3Result("ERROR: S3 setup failed: ${e.toString()}");
                          return;
                        }
                        _s3Result("S3 setup successful");
                      }),
                  const SizedBox(width: 10),
                  if (_s3Result().length == 1) const ProgressBar()
                ],
              ),
              if (_s3Result().length > 1) buildTestResult(_s3Result),
              const SizedBox(height: 20),
              InfoBar(
                title: Text("Email test"),
                severity: InfoBarSeverity.info,
                content: Text(
                    "Use the following button to test whether your server can send emails properly. A password-reset-like email should be delivered to the target email address."),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoTextField(
                    placeholder: "Target email",
                    controller: testEmailController,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                          child: Text("Send test email"),
                          onPressed: () async {
                            _emailResult(".");
                            try {
                              await state.pb!.settings.testEmail(testEmailController.text, "password-reset");
                            } catch (e) {
                              _emailResult("ERROR: email sending failed: ${e.toString()}");
                              return;
                            }
                            _emailResult("Email sent successfully, please check your inbox.");
                          }),
                      const SizedBox(width: 10),
                      if (_emailResult().length == 1) const ProgressBar()
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_emailResult().length > 1) buildTestResult(_emailResult),
                ],
              ),
            ].map((e) => [e, const SizedBox(height: 10)]).expand((e) => e).toList(),
          ),
        ),
      ),
    );
  }

  InfoBar buildTestResult(ObservableState<String> st) {
    return InfoBar(
      title: st().startsWith("ERROR") ? Text("Error") : Text("Success"),
      content: Text(st()),
      severity: st().startsWith("ERROR") ? InfoBarSeverity.error : InfoBarSeverity.success,
    );
  }

  @override
  List<ObservableBase> getObservableState() {
    return [_s3Result, _emailResult];
  }
}

final _s3Result = ObservableState("");
final _emailResult = ObservableState("");
