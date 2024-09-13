import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/adapters.dart';
import './observing_widget.dart';
import './model.dart';
import '../utils/uuid.dart';

/// This file introduces 5 types of observable objects
/// all of which will notify their observers and automatically updates ObservableWidgets
/// when their properties change
/// - ObservableBase: would rarely be useful
/// - ObservableState: would be useful for storing standalone observable state (not part of a class)
/// - ObservableObject: should be used when you want a collection of state (that are somehow related)
/// - ObservablePersistingObject: same as above but with persistence
/// - ObservableList: Typically used by stores

typedef OEventCallback = void Function(List<OEvent>);

class CustomError {
  final String message;
  final StackTrace stackTrace;
  CustomError(this.message, this.stackTrace);
}

class Observer {
  final String id = uuid();
  final OEventCallback callback;
  Observer(OEventCallback cb) : callback = cb;
}

enum EventType {
  add,
  modify,
  remove,
}

class OEvent {
  final EventType type;
  final int index;
  final String id;
  final String? property;
  OEvent.add(this.index, this.id)
      : type = EventType.add,
        property = null;
  OEvent.modify(this.index, this.id, [this.property]) : type = EventType.modify;
  OEvent.remove(this.index, this.id)
      : type = EventType.remove,
        property = null;
}

/// Base observable class
/// the observable functionality of the application is all based on this class
class ObservableBase {
  ObservableBase() {
    observe((_) {
      for (var callback in viewUpdatersCallbacks) {
        callback();
      }
    });

    _stream.listen((events) {
      for (var observer in _observers) {
        try {
          observer.callback(events);
        } catch (message, stackTrace) {
          errors.add(CustomError(message.toString(), stackTrace));
        }
      }
    });
  }

  final StreamController<List<OEvent>> _controller = StreamController<List<OEvent>>.broadcast();
  final List<Observer> _observers = [];
  final List<CustomError> errors = [];
  Stream<List<OEvent>> get _stream => _controller.stream;
  double _silent = 0;

  void _notifyObservers(List<OEvent> events) {
    if (_silent == 0) _controller.add(events);
  }

  String observe(OEventCallback callback) {
    int existing = _observers.indexWhere((o) => o.callback == callback);
    if (existing > -1) {
      return _observers[existing].id;
    }
    Observer observer = Observer(callback);
    _observers.add(observer);
    return observer.id;
  }

  void unObserve(String id) {
    _observers.removeWhere((observer) => observer.id == id);
  }

  void dispose() {
    _silent = double.maxFinite;
    _observers.clear();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  void silently(void Function() fn) {
    _silent++;
    try {
      fn();
    } catch (e, stacktrace) {
      errors.add(CustomError(e.toString(), stacktrace));
    }
    _silent--;
  }
}

/// Creates a standalone observable value
/// this can be accessed by calling it "()"
/// and can be set by passing a value when calling it "(value)"
class ObservableState<T> extends ObservableObject {
  T _value;

  ObservableState(this._value);

  T call([T? newValue]) {
    if (newValue != null) {
      _value = newValue;
      notify();
    }
    return _value;
  }
}

/// creates an observable class that can be composed of multiple values
/// however, modifiers should be written as methods of this class
/// and should call notify() when the value is changed
class ObservableObject extends ObservableBase {
  void notify() {
    _notifyObservers([OEvent.modify(0, "")]);
  }
}

/// Behaves much like ObservableObject
/// but also persists its data to a hive box
/// however only data that are defined in toJson and fromJson will be persisted
abstract class ObservablePersistingObject extends ObservableObject {
  ObservablePersistingObject(this.identifier) {
    box = () async {
      await Hive.initFlutter();
      return Hive.openBox<String>(identifier);
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
    super.notify(); // calling it from super so we don't have to reload from box
  }

  @override
  void notify() {
    super.notify();
    box.then((loadedBox) {
      loadedBox.put(identifier, jsonEncode(toJson()));
    });
  }

  fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}

/// creates an observable list
/// values of this list should extend Model
/// this is typically used by stores (lists of models)
class ObservableList<T extends Model> extends ObservableBase {
  final List<T> _list = [];

  T firstWhere(bool Function(T) test) {
    return _list.where(test).first;
  }

  int indexWhere(bool Function(T) test) {
    return _list.indexWhere(test);
  }

  int indexOfId(String id) {
    return _list.indexWhere((item) => item.id == id);
  }

  void add(T item) {
    _list.add(item);
    _notifyObservers([OEvent.add(_list.length - 1, item.id)]);
  }

  void addAll(List<T> items) {
    int startIndex = _list.length;
    _list.addAll(items);
    List<OEvent> events = [];
    for (int i = 0; i < items.length; i++) {
      events.add(OEvent.add(startIndex + i, items[i].id));
    }
    _notifyObservers(events);
  }

  void remove(T item) {
    int index = indexOfId(item.id);
    if (index >= 0 && index < _list.length) {
      String id = _list[index].id;
      _list.removeAt(index);
      _notifyObservers([OEvent.remove(index, id)]);
    }
  }

  void modify(T item) {
    int index = indexOfId(item.id);
    if (index >= 0 && index < _list.length) {
      _list[index] = item;
      _notifyObservers([OEvent.modify(index, item.id)]);
    }
  }

  void clear() {
    _list.clear();
    _notifyObservers([OEvent.remove(-1, '')]);
  }

  void notifyView() {
    _notifyObservers([OEvent.modify(-1, 'ignore')]);
  }

  List<T> get docs => List.unmodifiable(_list);
}
