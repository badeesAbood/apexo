import 'package:apexo/backend/observable/observable.dart';
import 'package:flutter/material.dart';

abstract class ObservingWidget<T> extends StatefulWidget {
  const ObservingWidget({super.key});
  @override
  State<ObservingWidget> createState() => _ObservingWidgetState();

  // This function should be overridden by specific widgets
  List<ObservableBase> getObservableState();
  build(BuildContext context);
}

class _ObservingWidgetState extends State<ObservingWidget> {
  late void Function(List<OEvent>) _listener;

  @override
  void initState() {
    super.initState();
    _listener = (_) {
      if (mounted) setState(() {});
    };
    for (var observable in widget.getObservableState()) {
      observable.observe(_listener);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from state changes
    for (var observable in widget.getObservableState()) {
      observable.unObserve(_listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}
