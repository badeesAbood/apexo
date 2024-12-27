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
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

final paidController = TextEditingController();
final priceController = TextEditingController();
final postOpNotesController = TextEditingController();

openSingleAppointment({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Appointment) onSave,
  required bool editing,
  int selectedTab = 0,
}) {
  pages.openAppointment = Appointment.fromJson(json); // reset
  final o = pages.openAppointment;
  paidController.text = o.paid.toStringAsFixed(0);
  priceController.text = o.price.toStringAsFixed(0);
  postOpNotesController.text = o.postOpNotes;
  showTabbedModal(
      key: Key(o.id),
      context: context,
      onArchive: o.archived != true && editing ? () => appointments.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => appointments.set(o..archived = null) : null,
      onSave: () => appointments.set(o),
      onContinue: editing
          ? null
          : () {
              appointments.set(pages.openAppointment);
              openSingleAppointment(
                context: context,
                json: pages.openAppointment.toJson(),
                title: txt("editAppointment"),
                onSave: onSave,
                editing: true,
                selectedTab: 2,
              );
            },
      initiallySelected: selectedTab,
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
                controller: postOpNotesController,
                onChanged: (v) {
                  pages.openAppointment.postOpNotes = v;
                  pages.openAppointment.isDone(true);
                  state.notify();
                },
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
                  pages.openAppointment.isDone(true);
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
                    child: CupertinoTextField(
                      key: WK.fieldAppointmentPrice,
                      controller: priceController,
                      onChanged: (v) {
                        pages.openAppointment.price = double.tryParse(v) ?? 0;
                        pages.openAppointment.paid = double.tryParse(v) ?? 0;
                        paidController.text = pages.openAppointment.paid.toStringAsFixed(0);
                        pages.openAppointment.isDone(true);
                        state.notify();
                      },
                      placeholder: txt("price"),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InfoLabel(
                    label: "${txt("paidIn")} ${globalSettings.get("currency_______").value}",
                    child: CupertinoTextField(
                      key: WK.fieldAppointmentPayment,
                      controller: paidController,
                      onChanged: (v) {
                        pages.openAppointment.paid = double.tryParse(v) ?? 0;
                        pages.openAppointment.isDone(true);
                        state.notify();
                      },
                      placeholder: txt("paid"),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(direction: Axis.horizontal),
            Checkbox(
              checked: pages.openAppointment.isDone(),
              onChanged: (checked) {
                pages.openAppointment.isDone(checked);
                state.notify();
              },
              content: Text(txt("isDone")),
            ),
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
                              final imgName =
                                  await handleNewImage(rowID: pages.openAppointment.id, targetPath: img.path);
                              if (pages.openAppointment.imgs.contains(imgName) == false) {
                                pages.openAppointment.imgs.add(imgName);
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
                              final imgName =
                                  await handleNewImage(rowID: pages.openAppointment.id, targetPath: res.path);
                              if (pages.openAppointment.imgs.contains(imgName) == false) {
                                pages.openAppointment.imgs.add(imgName);
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
                        rowId: pages.openAppointment.id,
                        imgs: pages.openAppointment.imgs,
                        progress: state.progress,
                        onPressDelete: (img) async {
                          state.startProgress();
                          try {
                            await appointments.deleteImg(pages.openAppointment.id, img);
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
