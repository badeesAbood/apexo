import 'package:apexo/backend/utils/hash.dart';
import 'package:apexo/backend/utils/imgs.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/pages/calendar/dialog_import_photos.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/patients/modal_patient.dart';
import 'package:apexo/pages/print/print_prescription.dart';
import 'package:apexo/pages/shared/acrylic_button.dart';
import 'package:apexo/pages/shared/date_time_picker.dart';
import 'package:apexo/pages/shared/grid_gallery.dart';
import 'package:apexo/pages/shared/operators_picker.dart';
import 'package:apexo/pages/shared/patient_picker.dart';
import 'package:apexo/pages/shared/tabbed_modal.dart';
import 'package:apexo/pages/shared/tag_input.dart';
import 'package:apexo/state/stores/appointments/appointment_model.dart';
import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

openSingleAppointment({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Appointment) onSave,
  required bool editing,
}) {
  pages.openAppointment = Appointment.fromJson(json); // reset
  final o = pages.openAppointment;
  showTabbedModal(
      key: Key(o.id),
      context: context,
      onArchive: o.archived != true && editing ? () => appointments.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => appointments.set(o..archived = null) : null,
      onSave: () => appointments.set(o),
      tabs: [
        TabbedModal(
          title: title,
          icon: FluentIcons.add_event,
          closable: true,
          content: (state) => [
            InfoLabel(
              /// rebuild needed if a patient is selected/deselected
              key: Key(pages.openAppointment.patientID ?? ""),
              label: "${txt("patient")}:",
              child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: PatientPicker(
                      value: pages.openAppointment.patientID,
                      onChanged: (id) {
                        pages.openAppointment.patientID = id;
                        state.notify();
                      }),
                ),
                const SizedBox(width: 5),
                if (pages.openAppointment.patientID == null)
                  AcrylicButton(
                      icon: FluentIcons.add_friend,
                      text: txt("newPatient"),
                      onPressed: () {
                        openSinglePatient(
                          context: context,
                          json: {},
                          title: txt("newPatient"),
                          onSave: (patient) {
                            patients.set(patient);
                            pages.openAppointment.patientID = patient.id;
                            state.notify();
                          },
                          editing: false,
                        );
                      })
              ]),
            ),
            InfoLabel(
              label: "${txt("doctors")}:",
              child: OperatorsPicker(
                  value: pages.openAppointment.operatorsIDs,
                  onChanged: (s) {
                    pages.openAppointment.operatorsIDs = s;
                    state.notify();
                  }),
            ),
            Column(
              children: [
                InfoLabel(
                  label: "${txt("date")}:",
                  child: DateTimePicker(
                    key: WK.fieldAppointmentDate,
                    value: pages.openAppointment.date(),
                    onChange: (d) {
                      pages.openAppointment.date(d);
                      state.notify();
                    },
                    buttonText: txt("changeDate"),
                    buttonIcon: FluentIcons.calendar,
                    format: "d MMMM yyyy",
                  ),
                ),
                const SizedBox(height: 5),
                if (pages.openAppointment.operators.isNotEmpty &&
                    !pages.openAppointment.availableWeekDays.contains(pages.openAppointment.date().weekday))
                  InfoBar(
                    title: Text(txt("attention")),
                    content: Text(txt("doctorNotAvailable")),
                    severity: InfoBarSeverity.warning,
                  )
              ],
            ),
            InfoLabel(
              label: "${txt("time")}:",
              child: DateTimePicker(
                key: WK.fieldAppointmentTime,
                value: pages.openAppointment.date(),
                onChange: (d) => pages.openAppointment.date(d),
                buttonText: txt("changeTime"),
                pickTime: true,
                buttonIcon: FluentIcons.clock,
                format: "hh:mm a",
              ),
            ),
            InfoLabel(
              label: "${txt("preOperativeNotes")}:",
              child: CupertinoTextField(
                key: WK.fieldAppointmentPreOpNotes,
                expands: true,
                maxLines: null,
                controller: TextEditingController(text: pages.openAppointment.preOpNotes),
                onChanged: (v) => pages.openAppointment.preOpNotes = v,
                placeholder: "${txt("preOperativeNotes")}...",
              ),
            ),
          ],
        ),
        TabbedModal(
          title: txt("operativeDetails"),
          icon: FluentIcons.medical_care,
          closable: true,
          content: (state) => [
            InfoLabel(
              label: "${txt("postOperativeNotes")}:",
              child: CupertinoTextField(
                key: WK.fieldAppointmentPostOpNotes,
                expands: true,
                maxLines: null,
                controller: TextEditingController(text: pages.openAppointment.postOpNotes),
                onChanged: (v) => pages.openAppointment.postOpNotes = v,
                placeholder: "${txt("postOperativeNotes")}...",
              ),
            ),
            InfoLabel(
              label: "${txt("prescription")}:",
              child: TagInputWidget(
                key: WK.fieldAppointmentPrescriptions,
                suggestions: appointments.allPrescriptions.map((p) => TagInputItem(value: p, label: p)).toList(),
                onChanged: (s) {
                  pages.openAppointment.prescriptions = s.where((x) => x.value != null).map((x) => x.value!).toList();
                  state.notify();
                },
                initialValue: pages.openAppointment.prescriptions.map((p) => TagInputItem(value: p, label: p)).toList(),
                strict: false,
                limit: 999,
                placeholder: "${txt("prescription")}...",
              ),
            ),
            if (pages.openAppointment.prescriptions.isNotEmpty)
              FilledButton(
                  style: const ButtonStyle(elevation: WidgetStatePropertyAll(2)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.print),
                      const SizedBox(width: 10),
                      Text(txt("printPrescription"))
                    ],
                  ),
                  onPressed: () {
                    printingPrescription(
                      context,
                      pages.openAppointment.prescriptions,
                      pages.openAppointment.patient?.title ?? "",
                      pages.openAppointment.patient?.age.toString() ?? "",
                      pages.openAppointment.patient?.webPageLink.toString() ?? "",
                    );
                  }),
            const Divider(direction: Axis.horizontal),
            Row(
              children: [
                Expanded(
                  child: InfoLabel(
                    label: "${txt("priceIn")} ${globalSettings.get("currency_______").value}",
                    child: NumberBox(
                      key: WK.fieldAppointmentPrice,
                      value: pages.openAppointment.price,
                      onChanged: (v) => pages.openAppointment.price = v ?? 0,
                      placeholder: txt("price"),
                      mode: SpinButtonPlacementMode.inline,
                    ),
                  ),
                ),
                Expanded(
                  child: InfoLabel(
                    label: "${txt("paidIn")} ${globalSettings.get("currency_______").value}",
                    child: NumberBox(
                      key: WK.fieldAppointmentPayment,
                      value: pages.openAppointment.paid,
                      onChanged: (v) => pages.openAppointment.paid = v ?? 0,
                      placeholder: txt("paid"),
                      mode: SpinButtonPlacementMode.inline,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        if (editing)
          TabbedModal(
            title: txt("gallery"),
            icon: FluentIcons.camera,
            closable: true,
            padding: 0,
            spacing: 0,
            actions: kIsWeb
                ? [
                    /// TODO: uploading images from the web is not supported
                    /// currently we're not supporting uploading images from the web
                    /// if we're planning to support it, we should clean the images uploading functions first
                    /// - should they accept an array?
                    /// - should they accept a single image?
                    /// - XFile vs File?
                    /// - Http.MultipartFile.fromPath while we already had an XFile/File!! this doesn't seem right!
                    /// - also how are we going to approach deferred image uploading in the web! given that we're dealing with a blob that gets revoked!
                    /// - we should have testing ready for image uploading scenarios before making changes, I think it's very fragile!
                    ///
                    /// There's a lot of details to be considered before we can tackle this
                    ///
                    /// Why we should support uploading images from the web?
                    /// This decision should be based on whether the application is going to be published in the iOS app store or not.
                    ///
                    /// Note: Image viewing and deleting is supported!
                  ]
                : [
                    TabAction(
                      text: txt("link"),
                      icon: FluentIcons.link,
                      callback: (state) {
                        () async {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return ImportDialog(state: state);
                              });
                        }();
                        return false;
                      },
                    ),
                    TabAction(
                      text: txt("upload"),
                      callback: (state) {
                        () async {
                          List<XFile> res =
                              await ImagePicker().pickMultiImage(limit: 50 - pages.openAppointment.imgs.length);
                          state.startProgress();
                          try {
                            for (var img in res) {
                              // copy
                              final newFileName = simpleHash(img.path) + path.extension(img.path);
                              final savedFile = await savePickedImage(img, newFileName);
                              // upload
                              await appointments.uploadImgs(pages.openAppointment.id, [savedFile.path]);
                              // update model
                              if (pages.openAppointment.imgs.contains(newFileName) == false) {
                                pages.openAppointment.imgs.add(newFileName);
                                appointments.set(pages.openAppointment);
                              }
                            }
                          } catch (e, s) {
                            logger("Error during file upload: $e", s);
                          }
                          state.endProgress();
                        }();
                        return false;
                      },
                      icon: FluentIcons.photo2_add,
                    ),
                    if (ImagePicker().supportsImageSource(ImageSource.camera))
                      TabAction(
                        text: txt("camera"),
                        callback: (state) {
                          () async {
                            XFile? res = await ImagePicker().pickImage(source: ImageSource.camera);
                            if (res == null) return;
                            state.startProgress();
                            try {
                              // copy
                              final newFileName = simpleHash(res.path) + path.extension(res.path);
                              final file = await savePickedImage(res, newFileName);
                              // upload image
                              await appointments.uploadImgs(pages.openAppointment.id, [file.path]);
                              // update the model
                              if (pages.openAppointment.imgs.contains(newFileName) == false) {
                                pages.openAppointment.imgs.add(newFileName);
                                appointments.set(pages.openAppointment);
                              }
                            } catch (e, s) {
                              logger("Error during uploading camera capture: $e", s);
                            }
                            state.endProgress();
                          }();
                          return false;
                        },
                        icon: FluentIcons.camera,
                      ),
                  ],
            content: (state) => [
              pages.openAppointment.imgs.isEmpty
                  ? InfoBar(title: Text(txt("emptyGallery")), content: Text(txt("noPhotos")))
                  : SingleChildScrollView(
                      child: GridGallery(
                        imgs: pages.openAppointment.imgs,
                        onPressDelete: (img) async {
                          state.startProgress();
                          try {
                            await appointments.uploadImgs(pages.openAppointment.id, [img], false);
                            pages.openAppointment.imgs.remove(img);
                            appointments.set(pages.openAppointment);
                          } catch (e, s) {
                            logger("Error during deleting image: $e", s);
                          }
                          state.endProgress();
                        },
                      ),
                    )
            ],
          )
      ]);
}
