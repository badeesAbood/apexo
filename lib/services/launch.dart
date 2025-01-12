import 'package:apexo/core/observable.dart';

class _Launch {
  final dialogShown = ObservableState(false);
  final isFirstLaunch = ObservableState(false);
  final isDemo = Uri.base.host == "demo.apexo.app";
  final open = ObservableState(false);
  double layoutWidth = 0;
}

final launch = _Launch();
