import 'package:apexo/core/observable.dart';

class _Launch {
  final dialogShown = ObservableState(false);
  final isFirstLaunch = ObservableState(false);
  final isDemo = ObservableState(Uri.base.host == "demo.apexo.app");
  final open = ObservableState(false);
}

final launch = _Launch();
