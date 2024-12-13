import 'package:apexo/backend/utils/colors_without_yellow.dart';
import 'package:apexo/backend/utils/get_deterministic_item.dart';
import 'package:apexo/pages/stats/reusable_styled_charts/common.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';

class StyledRadarChart extends StatefulWidget {
  final List<List<double>> data;
  final List<String> labels;
  const StyledRadarChart({required this.data, required this.labels, super.key});

  @override
  State<StyledRadarChart> createState() => _StyledRadarChartState();
}

class _StyledRadarChartState extends State<StyledRadarChart> {
  String currentLabel = '';
  double currentValue = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const Center(child: Text('No data'));
    for (var set in widget.data) {
      if (set.length < 3) return const Center(child: Text('No data'));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: RadarChart(RadarChartData(
              borderData: border(),
              gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
              tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
              radarBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
              getTitle: (index, angle) => RadarChartTitle(text: widget.labels[index]),
              titlePositionPercentageOffset: 0.2,
              radarTouchData: RadarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (response == null || response.touchedSpot == null) {
                      return setState(() {
                        currentLabel = "";
                        currentValue = 0;
                      });
                    }

                    final value = response.touchedSpot!.touchedRadarEntry.value;
                    final label = widget.labels[response.touchedSpot!.touchedRadarEntryIndex];
                    setState(() {
                      currentLabel = label;
                      currentValue = value;
                    });
                  }),
              tickCount: 1,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              titleTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
              radarShape: RadarShape.polygon,
              dataSets: List.generate(widget.data.length, (setIndex) {
                Color color = getDeterministicItem(colorsWithoutYellow, widget.labels.join() + setIndex.toString());
                return RadarDataSet(
                  borderColor: color,
                  borderWidth: 1,
                  fillColor: color.withOpacity(0.1),
                  dataEntries: List.generate(widget.data[setIndex].length, (valueIndex) {
                    return RadarEntry(value: widget.data[setIndex][valueIndex]);
                  }),
                );
              }),
            )),
          ),
          const SizedBox(height: 15),
          Text(currentLabel.isEmpty ? "" : "$currentLabel : ${currentValue.toStringAsFixed(0)}"),
        ],
      ),
    );
  }
}
