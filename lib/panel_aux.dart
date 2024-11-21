import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
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
        const SizedBox(width: 5),
        Text(state.email),
        const SizedBox(width: 5),
        Button(
          onPressed: state.logout,
          child: Row(
            children: [
              const Icon(FluentIcons.sign_out),
              const SizedBox(width: 3),
              Text(txt("logout")),
            ],
          ),
        ),
      ],
    );
  }
}

const auxiliaryIcon = CupertinoIcons.person;
