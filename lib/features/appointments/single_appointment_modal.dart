import 'package:apexo/app/routes.dart';
import 'package:apexo/features/doctors/doctors_store.dart';
import 'package:apexo/utils/imgs.dart';
import 'package:apexo/utils/logger.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/common_widgets/dialogs/import_photos_dialog.dart';
import 'package:apexo/features/patients/single_patient_modal.dart';
import 'package:apexo/utils/print/print_prescription.dart';
import 'package:apexo/common_widgets/acrylic_button.dart';
import 'package:apexo/common_widgets/date_time_picker.dart';
import 'package:apexo/common_widgets/grid_gallery.dart';
import 'package:apexo/common_widgets/operators_picker.dart';
import 'package:apexo/common_widgets/patient_picker.dart';
import 'package:apexo/common_widgets/tabbed_modal.dart';
import 'package:apexo/common_widgets/tag_input.dart';
import 'package:apexo/features/appointments/appointment_model.dart';
import 'package:apexo/features/appointments/appointments_store.dart';
import 'package:apexo/features/patients/patients_store.dart';
import 'package:apexo/features/settings/settings_stores.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

final paidController = TextEditingController();
final priceController = TextEditingController();
final postOpNotesController = TextEditingController();
bool didNotEditPaidYet = true;

openSingleAppointment({
  required BuildContext context,
  required Map<String, dynamic> json,
  required String title,
  required void Function(Appointment) onSave,
  required bool editing,
  int selectedTab = 0,
}) {
  routes.openAppointment = Appointment.fromJson(json); // reset
  final o = routes.openAppointment;
  paidController.text = o.paid.toStringAsFixed(0);
  priceController.text = o.price.toStringAsFixed(0);
  didNotEditPaidYet = true;
  postOpNotesController.text = o.postOpNotes;
  showTabbedModal(
      key: Key(o.id),
      context: context,
      streams: [
        patients.observableObject.stream,
        appointments.observableObject.stream,
        doctors.observableObject.stream
      ],
      onArchive: o.archived != true && editing ? () => appointments.set(o..archived = true) : null,
      onRestore: o.archived == true && editing ? () => appointments.set(o..archived = null) : null,
      onSave: () => appointments.set(o),
      onContinue: editing
          ? null
          : () {
              appointments.set(routes.openAppointment);
              openSingleAppointment(
                context: context,
                json: routes.openAppointment.toJson(),
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
              key: Key(routes.openAppointment.patientID ?? ""),
              label: "${txt("patient")}:",
              child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: PatientPicker(
                      value: routes.openAppointment.patientID,
                      onChanged: (id) {
                        routes.openAppointment.patientID = id;
                        state.notify();
                      }),
                ),
                const SizedBox(width: 5),
                if (routes.openAppointment.patientID == null)
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
                            routes.openAppointment.patientID = patient.id;
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
                  value: routes.openAppointment.operatorsIDs,
                  onChanged: (s) {
                    routes.openAppointment.operatorsIDs = s;
                    state.notify();
                  }),
            ),
            Column(
              children: [
                InfoLabel(
                  label: "${txt("date")}:",
                  child: DateTimePicker(
                    key: WK.fieldAppointmentDate,
                    value: routes.openAppointment.date,
                    onChange: (d) {
                      routes.openAppointment.date = d;
                      state.notify();
                    },
                    buttonText: txt("changeDate"),
                    buttonIcon: FluentIcons.calendar,
                    format: "d MMMM yyyy",
                  ),
                ),
                const SizedBox(height: 5),
                if (routes.openAppointment.operators.isNotEmpty &&
                    !routes.openAppointment.availableWeekDays.contains(routes.openAppointment.date.weekday))
                  InfoBar(
                    title: Txt(txt("attention")),
                    content: Txt(txt("doctorNotAvailable")),
                    severity: InfoBarSeverity.warning,
                  )
              ],
            ),
            InfoLabel(
              label: "${txt("time")}:",
              child: DateTimePicker(
                key: WK.fieldAppointmentTime,
                value: routes.openAppointment.date,
                onChange: (d) => routes.openAppointment.date = d,
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
                controller: TextEditingController(text: routes.openAppointment.preOpNotes),
                onChanged: (v) => routes.openAppointment.preOpNotes = v,
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
                  routes.openAppointment.postOpNotes = v;
                  routes.openAppointment.isDone = true;
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
                  routes.openAppointment.prescriptions = s.where((x) => x.value != null).map((x) => x.value!).toList();
                  routes.openAppointment.isDone = true;
                  state.notify();
                },
                initialValue:
                    routes.openAppointment.prescriptions.map((p) => TagInputItem(value: p, label: p)).toList(),
                strict: false,
                limit: 999,
                placeholder: "${txt("prescription")}...",
              ),
            ),
            if (routes.openAppointment.prescriptions.isNotEmpty)
              FilledButton(
                  style: const ButtonStyle(elevation: WidgetStatePropertyAll(2)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [const Icon(FluentIcons.print), const SizedBox(width: 10), Txt(txt("printPrescription"))],
                  ),
                  onPressed: () {
                    printingPrescription(
                      context,
                      routes.openAppointment.prescriptions,
                      routes.openAppointment.patient?.title ?? "",
                      routes.openAppointment.patient?.age.toString() ?? "",
                      routes.openAppointment.patient?.webPageLink.toString() ?? "",
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
                        routes.openAppointment.price = double.tryParse(v) ?? 0;
                        if (didNotEditPaidYet) {
                          routes.openAppointment.paid = double.tryParse(v) ?? 0;
                          paidController.text = routes.openAppointment.paid.toStringAsFixed(0);
                        }
                        routes.openAppointment.isDone = true;
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
                        didNotEditPaidYet = false;
                        routes.openAppointment.paid = double.tryParse(v) ?? 0;
                        routes.openAppointment.isDone = true;
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
              checked: routes.openAppointment.isDone,
              onChanged: (checked) {
                routes.openAppointment.isDone = checked == true;
                state.notify();
              },
              content: Txt(txt("isDone")),
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
                              await ImagePicker().pickMultiImage(limit: 50 - routes.openAppointment.imgs.length);
                          state.startProgress();
                          try {
                            for (var img in res) {
                              final imgName =
                                  await handleNewImage(rowID: routes.openAppointment.id, targetPath: img.path);
                              if (routes.openAppointment.imgs.contains(imgName) == false) {
                                routes.openAppointment.imgs.add(imgName);
                                appointments.set(routes.openAppointment);
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
                                  await handleNewImage(rowID: routes.openAppointment.id, targetPath: res.path);
                              if (routes.openAppointment.imgs.contains(imgName) == false) {
                                routes.openAppointment.imgs.add(imgName);
                                appointments.set(routes.openAppointment);
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
              routes.openAppointment.imgs.isEmpty
                  ? InfoBar(title: Txt(txt("emptyGallery")), content: Txt(txt("noPhotos")))
                  : SingleChildScrollView(
                      child: GridGallery(
                        rowId: routes.openAppointment.id,
                        imgs: routes.openAppointment.imgs,
                        progress: state.progress,
                        onPressDelete: (img) async {
                          state.startProgress();
                          try {
                            await appointments.deleteImg(routes.openAppointment.id, img);
                            routes.openAppointment.imgs.remove(img);
                            appointments.set(routes.openAppointment);
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
