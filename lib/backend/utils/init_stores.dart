import 'package:apexo/state/stores/appointments/appointments_store.dart';
import 'package:apexo/state/stores/expenses/expenses_store.dart';
import 'package:apexo/state/stores/labworks/labworks_store.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';

initializeStores() {
  staff.init();
  patients.init();
  appointments.init();
  globalSettings.init();
  localSettings.init();
  labworks.init();
  expenses.init();
}
