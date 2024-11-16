import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/state/charts.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

class RangeControl extends ObservingWidget {
  const RangeControl({
    super.key,
    required Color color,
    required TextStyle textStyle,
    required List<IconData> icons,
  })  : _color = color,
        _textStyle = textStyle,
        _icons = icons;

  final Color _color;
  final TextStyle _textStyle;
  final List<IconData> _icons;

  @override
  Widget build(BuildContext context) {
    final df = localSettings.get("date_format")?.value.startsWith("d") == true ? "dd/MM" : "MM/dd";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => chartsState.rangePicker(context),
            icon: Row(
              children: [
                Transform.flip(
                    flipX: true,
                    child: Icon(
                      FluentIcons.calendar_reply,
                      size: 20,
                      color: _color,
                    )),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Start", style: _textStyle),
                    Text(DateFormat("$df/yyyy").format(chartsState.start), style: _textStyle),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: chartsState.toggleInterval,
            icon: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      _icons[StatsInterval.values.indexOf(chartsState.interval)],
                      size: 20,
                      color: _color,
                    ),
                    const SizedBox(width: 5),
                    Text("${chartsState.periods.length} ${chartsState.intervalString}", style: _textStyle)
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => chartsState.rangePicker(context),
            icon: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("End", style: _textStyle),
                    Text(DateFormat("$df/yyyy").format(chartsState.end), style: _textStyle),
                  ],
                ),
                const SizedBox(width: 10),
                Icon(FluentIcons.calendar_reply, size: 20, color: _color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  getObservableState() {
    return [chartsState];
  }
}
