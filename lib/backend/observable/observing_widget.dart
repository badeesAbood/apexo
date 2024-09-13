import 'package:flutter/material.dart';

List<void Function()> viewUpdatersCallbacks = [];

abstract class ObservingWidget extends StatefulWidget {
  const ObservingWidget({super.key});
  @override
  State<ObservingWidget> createState() => _ObservingWidgetState();
  build(BuildContext context);
}

class _ObservingWidgetState extends State<ObservingWidget> {
  @override
  void initState() {
    viewUpdatersCallbacks.add(() {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}
