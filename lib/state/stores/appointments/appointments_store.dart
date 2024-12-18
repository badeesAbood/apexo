import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../state/state.dart';
import './appointment_model.dart';
import '../../../backend/observable/store.dart';

const _storeName = "appointments";

class Appointments extends Store<Appointment> {
  Appointments()
      : super(
          modeling: Appointment.fromJson,
          onSyncStart: () {
            state.isSyncing++;
            state.notify();
          },
          onSyncEnd: () {
            state.isSyncing--;
            state.notify();
          },
        );

  Map<String, Map<String, List<Appointment>>> byPatient = {};
  Map<String, Map<String, List<Appointment>>> byDoctor = {};

  @override
  init() {
    super.init();

    observableObject.observe((_) => _allPrescriptions = null);
    observableObject.observe((_) {
      byPatient = {};
      byDoctor = {};
      for (var appointment in observableObject.values) {
        final patientID = appointment.patientID ?? "";
        final isDone = appointment.isDone();
        final isUpcoming = appointment.date().isAfter(DateTime.now());
        final isPast = appointment.date().isBefore(DateTime.now());

        // build patient caches
        if (byPatient[patientID] == null) {
          byPatient[patientID] = {
            "upcoming": [],
            "done": [],
            "past": [],
            "all": [],
          };
        }
        byPatient[patientID]!["all"]!.add(appointment);
        if (isUpcoming) {
          byPatient[patientID]!["upcoming"]!.add(appointment);
        } else if (isDone) {
          byPatient[patientID]!["done"]!.add(appointment);
        } else if (isPast) {
          byPatient[patientID]!["past"]!.add(appointment);
        }

        // build doctor caches
        for (var doctorId in appointment.operatorsIDs) {
          if (byDoctor[doctorId] == null) {
            byDoctor[doctorId] = {
              "upcoming": [],
              "done": [],
              "past": [],
              "all": [],
            };
          }
          byDoctor[doctorId]!["all"]!.add(appointment);
          if (isUpcoming) {
            byDoctor[doctorId]!["upcoming"]!.add(appointment);
          } else if (isDone) {
            byDoctor[doctorId]!["done"]!.add(appointment);
          } else if (isPast) {
            byDoctor[doctorId]!["past"]!.add(appointment);
          }
        }
      }
    });

    state.activators[_storeName] = () async {
      await loaded;

      local = SaveLocal(_storeName);
      await deleteMemoryAndLoadFromPersistence();
      remote = SaveRemote(
        pbInstance: state.pb!,
        storeName: _storeName,
        onOnlineStatusChange: (current) {
          if (state.isOnline != current) {
            state.isOnline = current;
            state.notify();
          }
        },
      );

      return () async {
        state.setLoadingIndicator("Synchronizing appointments");
        await synchronize();
        globalActions.syncCallbacks[_storeName] = synchronize;
        globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
      };
    };
  }

  String doctorId = "";

  Map<String, Appointment> get filtered {
    if (doctorId.isEmpty) return present;
    return Map<String, Appointment>.fromEntries(
        present.entries.where((entry) => entry.value.operatorsIDs.contains(doctorId)));
  }

  List<String>? _allPrescriptions;
  List<String> get allPrescriptions {
    return _allPrescriptions ??= Set<String>.from(present.values.expand((doc) => doc.prescriptions)).toList();
  }

  filterByDoctor(String? value) {
    doctorId = value ?? "";
    notify();
  }
}

final appointments = Appointments();
