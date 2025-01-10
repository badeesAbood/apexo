import 'dart:math';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/patients/patient_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:teeth_selector/teeth_selector.dart';

class DentalChart extends StatefulWidget {
  final Patient patient;

  const DentalChart({
    required this.patient,
    super.key,
  });

  @override
  State<DentalChart> createState() => _DentalChartState();
}

class _DentalChartState extends State<DentalChart> {
  bool showPermanent = true;
  bool showPrimary = false;
  String openTooth = "";
  final _noteController = TextEditingController();

  @override
  void initState() {
    showPrimary = widget.patient.age < 14 ||
        widget.patient.teeth.keys.any((tooth) =>
            tooth.startsWith("5") || tooth.startsWith("6") || tooth.startsWith("7") || tooth.startsWith("8"));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 25, 8, 35),
        child: Center(
          child: Builder(builder: (context) {
            // rebuild every time the widget is rebuilt
            // so that no tooth is selected
            final randomInt = Random().nextInt(4194967296);
            return TeethSelector(
              key: Key(randomInt.toString()),
              onChange: (selected) => setState(() {
                if (selected.isEmpty) {
                  openTooth = "";
                  _noteController.text = "";
                } else {
                  openTooth = selected.first;
                  _noteController.text = widget.patient.teeth[openTooth] ?? "";
                }
              }),
              notation: (isoString) => isoToTextualNotation(isoString),
              showPrimary: showPrimary,
              showPermanent: showPermanent,
              colorized:
                  widget.patient.teeth.map<String, Color>((entry, _) => MapEntry(entry, Colors.warningPrimaryColor))
                    ..addAll({openTooth: Colors.warningPrimaryColor}),
              selectedColor: Colors.grey,
              defaultStrokeWidth: 10,
            );
          }),
        ),
      ),
      Positioned(
        bottom: 0,
        child: SizedBox(
          width: 330,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Checkbox(
                  checked: showPermanent,
                  onChanged: (checked) => setState(() => showPermanent = checked == true),
                  content: Txt(txt("showPermanent")),
                ),
                Checkbox(
                  checked: showPrimary,
                  onChanged: (checked) => setState(() => showPrimary = checked == true),
                  content: Txt(txt("showPrimary")),
                ),
              ],
            ),
          ),
        ),
      ),
      if (openTooth.isNotEmpty) ...[
        if (isoToTextualNotation(openTooth).contains(txt("lower")))
          Positioned(
            top: 200,
            left: 120,
            child: Icon(FluentIcons.triangle_solid_down12, size: 90, color: Colors.white.withAlpha(250), shadows: [
              Shadow(
                color: Colors.grey.withAlpha(20),
                offset: const Offset(0, 10),
                blurRadius: 10,
              ),
            ]),
          ),
        if (isoToTextualNotation(openTooth).contains(txt("upper")))
          Positioned(
            bottom: 200,
            left: 120,
            child: Icon(FluentIcons.triangle_solid_up12, size: 90, color: Colors.white.withAlpha(250), shadows: [
              Shadow(
                color: Colors.grey.withAlpha(20),
                offset: const Offset(0, -10),
                blurRadius: 10,
              ),
            ]),
          ),
        Builder(builder: (context) {
          final tooth = isoToTextualNotation(openTooth);
          return Positioned(
            bottom: tooth.contains(txt("upper")) ? 100 : null,
            top: tooth.contains(txt("lower")) ? 100 : null,
            left: (340 - 300) * 0.5,
            child: Acrylic(
              elevation: 20,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              tintAlpha: 0,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Txt(isoToTextualNotation(openTooth), style: const TextStyle(fontSize: 12)),
                        IconButton(
                          icon: const Icon(FluentIcons.cancel),
                          onPressed: () => setState(() => openTooth = ""),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Divider(),
                    const SizedBox(height: 10),
                    TextFormBox(
                      placeholder: "Write notes here...",
                      maxLines: null,
                      controller: _noteController,
                    ),
                    const SizedBox(height: 5),
                    FilledButton(
                        child: Txt(txt("save")),
                        onPressed: () {
                          setState(() {
                            widget.patient.teeth[openTooth] = _noteController.text;
                            openTooth = "";
                          });
                        })
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    ]);
  }

  String isoToTextualNotation(String iso) {
    final quadrant = int.parse(iso.substring(0, 1));
    final tooth = int.parse(iso.substring(1));
    return """
          ${txt(stage[quadrant] ?? "")}
          ${txt(jaw[quadrant] ?? "")}
          ${txt(direction[quadrant] ?? "")}
          ${quadrant < 5 ? txt(namePermanent[tooth] ?? "") : txt(namePrimary[tooth] ?? "")}
    """
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
  }

  final Map<int, String> stage = {
    1: "permanent",
    2: "permanent",
    3: "permanent",
    4: "permanent",
    5: "primary",
    6: "primary",
    7: "primary",
    8: "primary",
  };

  final Map<int, String> jaw = {
    1: "upper",
    2: "upper",
    3: "lower",
    4: "lower",
    5: "upper",
    6: "upper",
    7: "lower",
    8: "lower",
  };

  final Map<int, String> direction = {
    1: "right",
    2: "left",
    3: "left",
    4: "right",
    5: "right",
    6: "left",
    7: "left",
    8: "right",
  };

  final Map<int, String> namePermanent = {
    1: "centralIncisor",
    2: "lateralIncisor",
    3: "canine",
    4: "firstPremolar",
    5: "secondPremolar",
    6: "firstMolar",
    7: "secondMolar",
    8: "thirdMolar",
  };

  final Map<int, String> namePrimary = {
    1: "centralIncisor",
    2: "lateralIncisor",
    3: "canine",
    4: "firstMolar",
    5: "secondMolar",
  };
}
