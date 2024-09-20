import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import './state/state.dart';

class AuxiliarySection extends ObservingWidget {
  @override
  getObservableState() {
    return [state];
  }

  const AuxiliarySection({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(auxiliaryIcon),
        const SizedBox(width: 10),
        FilledButton(
            onPressed: state.logout,
            child: const Row(
              children: [
                Icon(FluentIcons.sign_out),
                SizedBox(width: 10),
                Text("Logout"),
              ],
            )),
      ],
    );
  }
}

const auxiliaryIcon = CupertinoIcons.person;
