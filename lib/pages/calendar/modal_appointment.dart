import 'package:apexo/backend/utils/hash.dart';
import 'package:apexo/backend/utils/imgs.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/pages/calendar/dialog_import_photos.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/pages/patients/modal_patient.dart';
import 'package:apexo/pages/shared/acrylic_button.dart';
import 'package:apexo/pages/shared/archive_button.dart';
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
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
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
  List<TabAction> actions = [
    TabAction(
      text: "Save",
      icon: FluentIcons.save,
      callback: (_) {
        onSave(pages.openAppointment);
        return true;
      },
    )
  ];
  if (editing) actions.add(archiveButton(pages.openAppointment, appointments));

  showTabbedModal(context: context, tabs: [
    TabbedModal(
      title: title,
      icon: FluentIcons.add_event,
      closable: true,
      actions: actions,
      content: (state) => [
        InfoLabel(
          /// rebuild needed if a patient is selected/deselected
          key: Key(pages.openAppointment.patientID ?? ""),
          label: "Patient:",
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
                  text: "New patient",
                  onPressed: () {
                    openSinglePatient(
                      context: context,
                      json: {},
                      title: "New Patient",
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
          label: "Operators:",
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
              label: "Date:",
              child: DateTimePicker(
                value: pages.openAppointment.date(),
                onChange: (d) {
                  pages.openAppointment.date(d);
                  state.notify();
                },
                buttonText: "Change date",
                buttonIcon: FluentIcons.calendar,
                format: "d MMMM yyyy",
              ),
            ),
            const SizedBox(height: 5),
            if (pages.openAppointment.operators.isNotEmpty &&
                !pages.openAppointment.availableWeekDays.contains(pages.openAppointment.date().weekday))
              const InfoBar(
                title: Text("Attention"),
                content: Text("One of the selected operators might not be available on the selected date."),
                severity: InfoBarSeverity.warning,
              )
          ],
        ),
        InfoLabel(
          label: "Time:",
          child: DateTimePicker(
            value: pages.openAppointment.date(),
            onChange: (d) => pages.openAppointment.date(d),
            buttonText: "Change time",
            pickTime: true,
            buttonIcon: FluentIcons.clock,
            format: "hh:mm a",
          ),
        ),
        InfoLabel(
          label: "Pre-operative notes:",
          child: CupertinoTextField(
            expands: true,
            maxLines: null,
            controller: TextEditingController(text: pages.openAppointment.preOpNotes),
            onChanged: (v) => pages.openAppointment.preOpNotes = v,
            placeholder: "Pre-operative notes",
          ),
        ),
      ],
    ),
    if (editing)
      TabbedModal(
        title: "Operative details",
        icon: FluentIcons.medical_care,
        closable: true,
        actions: actions,
        content: (state) => [
          InfoLabel(
            label: "Post-operative notes",
            child: CupertinoTextField(
              expands: true,
              maxLines: null,
              controller: TextEditingController(text: pages.openAppointment.postOpNotes),
              onChanged: (v) => pages.openAppointment.postOpNotes = v,
              placeholder: "Post-operative notes",
            ),
          ),
          InfoLabel(
            label: "Prescriptions",
            child: TagInputWidget(
              suggestions: appointments.allPrescriptions.map((p) => TagInputItem(value: p, label: p)).toList(),
              onChanged: (s) {
                pages.openAppointment.prescriptions = s.where((x) => x.value != null).map((x) => x.value!).toList();
              },
              initialValue: pages.openAppointment.prescriptions.map((p) => TagInputItem(value: p, label: p)).toList(),
              strict: false,
              limit: 999,
              placeholder: "prescriptions",
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InfoLabel(
                  label: "Price in ${globalSettings.get("currency_______")?.value}",
                  child: NumberBox(
                    value: pages.openAppointment.price,
                    onChanged: (v) => pages.openAppointment.price = v ?? 0,
                    placeholder: "Price",
                    mode: SpinButtonPlacementMode.inline,
                  ),
                ),
              ),
              Expanded(
                child: InfoLabel(
                  label: "Paid in ${globalSettings.get("currency_______")?.value}",
                  child: NumberBox(
                    value: pages.openAppointment.paid,
                    onChanged: (v) => pages.openAppointment.paid = v ?? 0,
                    placeholder: "Paid",
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
        title: "Gallery",
        icon: FluentIcons.camera,
        closable: true,
        padding: 0,
        spacing: 0,
        actions: [
          TabAction(
            text: "Link",
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
            text: "Upload",
            callback: (state) {
              () async {
                List<XFile> res = await ImagePicker().pickMultiImage(limit: 50 - pages.openAppointment.imgs.length);
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
              text: "Camera",
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
              ? const InfoBar(
                  title: Text("Empty gallery"),
                  content: Text("Currently the gallery for this appointment is empty"),
                )
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
