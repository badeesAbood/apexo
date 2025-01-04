import 'dart:async';
import 'dart:convert';
import 'package:apexo/utils/safe_dir.dart';
import 'package:apexo/utils/logger.dart';
import 'package:apexo/utils/safe_hive_init.dart';
import 'package:hive_flutter/adapters.dart';
import 'model.dart';

/// This file introduces 5 types of observable objects
/// all of which will notify their observers and automatically updates ObservableWidgets
/// when their properties change
/// - ObservableBase: would rarely be useful
/// - ObservableState: would be useful for storing standalone observable state (not part of a class)
/// - ObservablePersistingObject: same as above but with persistence
/// - ObservableList: Typically used by stores

typedef OEventCallback<V> = void Function(List<OEvent> events);

enum EventType {
  add,
  modify,
  remove,
}

class OEvent {
  final EventType type;
  final String id;
  OEvent.add(this.id) : type = EventType.add;
  OEvent.modify(this.id) : type = EventType.modify;
  OEvent.remove(this.id) : type = EventType.remove;
}

/// Base observable class
/// the observable functionality of the application is all based on this class
class ObservableBase<V> {
  ObservableBase() {
    stream.listen((events) {
      for (var observer in observers) {
        try {
          observer(events);
        } catch (e, s) {
          logger("Error while trying to register an observer: $e", s);
        }
      }
    });
  }

  final StreamController<List<OEvent>> _controller = StreamController<List<OEvent>>.broadcast();
  final List<OEventCallback<V>> observers = [];
  Stream<List<OEvent>> get stream => _controller.stream;
  double _silent = 0;
  final List<OEvent> _nextEvents = [];
  Timer? _timer;

  void notifyObservers(List<OEvent> events) {
    if (_silent != 0) return;
    _nextEvents.addAll(events);
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(const Duration(milliseconds: 50), () {
      _controller.add(_nextEvents);
      _nextEvents.clear();
    });
  }

  int observe(OEventCallback<V> callback) {
    int existing = observers.indexWhere((o) => o == callback);
    if (existing > -1) {
      return existing;
    }
    observers.add(callback);
    return observers.length - 1;
  }

  void unObserve(OEventCallback<V> callback) {
    observers.removeWhere((existing) => existing == callback);
  }

  void dispose() {
    _silent = double.maxFinite;
    observers.clear();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  void silently(void Function() fn) {
    _silent++;
    try {
      fn();
    } catch (e, s) {
      logger("Error during silent modification: $e", s);
    }
    _silent--;
  }
}

/// Creates a standalone observable value
/// this can be accessed by calling it "()"
/// and can be set by passing a value when calling it "(value)"
class ObservableState<T> extends ObservableBase<T> {
  T _value;

  ObservableState(this._value);

  T call([T? newValue]) {
    if (newValue != null) {
      _value = newValue;
      notifyObservers([OEvent.modify("__self__")]);
    }
    return _value;
  }
}

/// Persists its data to a hive box
/// however only data that are defined in toJson and fromJson will be persisted
abstract class ObservablePersistingObject extends ObservableBase<Map<String, dynamic>> {
  ObservablePersistingObject(this.identifier) {
    box = () async {
      await safeHiveInit();
      return Hive.openBox<String>(identifier, path: await filesDir());
    }();
    _initialLoad();
  }

  String identifier;
  late Future<Box<String>> box;

  _initialLoad() async {
    var value = (await box).get(identifier);
    if (value == null) {
      return;
    }
    fromJson(jsonDecode(value));
    super.notifyObservers([OEvent.modify("__self__")]); // calling it from super so we don't have to reload from box
  }

  @override
  void notifyObservers(List<OEvent> events) {
    super.notifyObservers(events);
    box.then((loadedBox) {
      loadedBox.put(identifier, jsonEncode(toJson()));
    });
  }

  // a short hand for calling notifyObservers
  notifyAndPersist() => notifyObservers([OEvent.modify("__self__")]);

  fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

/// creates an observable dictionary
/// values of this dictionary should extend Model
/// this is typically used by stores (dictionaries of models)
class ObservableDict<G extends Model> extends ObservableBase<G?> {
  final Map<String, G> _dictionary = {};

  G? get(String id) {
    return _dictionary[id];
  }

  void set(G item) {
    bool isNew = !_dictionary.containsKey(item.id);
    _dictionary[item.id] = item;
    notifyObservers([
      if (isNew) OEvent.add(item.id) else OEvent.modify(item.id),
    ]);
  }

  void setAll(List<G> items) {
    for (var item in items) {
      _dictionary[item.id] = item;
    }
    notifyObservers(items.map((item) => OEvent.add(item.id)).toList());
  }

  void remove(String id) {
    if (_dictionary.containsKey(id)) {
      _dictionary.remove(id);
      notifyObservers([OEvent.remove(id)]);
    }
  }

  void clear() {
    _dictionary.clear();
    notifyObservers([OEvent.remove('__removed_all__')]);
  }

  void notifyView() {
    notifyObservers([OEvent.modify('__ignore_view__')]);
  }

  List<G> get values => _dictionary.values.toList();

  List<String> get keys => _dictionary.keys.toList();

  Map<String, G> get docs => Map<String, G>.unmodifiable(_dictionary);
}
