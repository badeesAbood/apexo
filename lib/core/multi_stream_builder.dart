import 'dart:async';
import 'package:flutter/widgets.dart';

/// This widget builder simply builds a widget that depends on a list of streams
class MStreamBuilder<T> extends StatefulWidget {
  final List<Stream<T>> streams;
  final Widget Function(BuildContext context, List<T?> data) builder;

  const MStreamBuilder({
    required this.streams,
    required this.builder,
    super.key,
  });

  @override
  createState() => _MStreamBuilderState<T>();
}

class _MStreamBuilderState<T> extends State<MStreamBuilder<T>> {
  late List<T?> _data;
  late List<StreamSubscription<T>> _subscriptions;

  @override
  void initState() {
    super.initState();
    _data = List<T?>.filled(widget.streams.length, null);
    _subscriptions = widget.streams.asMap().entries.map((entry) {
      final index = entry.key;
      final stream = entry.value;
      return stream.listen((value) {
        setState(() {
          _data[index] = value;
        });
      });
    }).toList();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _data);
  }
}
