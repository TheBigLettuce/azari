// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

abstract class EventStreamsTable {
  EventStreamsTable(this.rootStream);

  factory EventStreamsTable.basic(
    Stream<EventData> rootStream,
    Conditions conditions,
  ) = _DefaultEventStreamsTable;

  final Stream<EventData> rootStream;

  Conditions get conditions;

  bool hasListeners(EventCondition c);

  void addTransformer(EventData Function(EventData) f);
  void removeTransformer(EventData Function(EventData) f);

  Stream<void> forCondition(
    EventCondition c, [
    bool fire = false,
  ]);

  void clear();
  void destroy();
}

abstract class Conditions {
  bool isOfThis(EventCondition c);

  dynamic processEvent(EventData e);
  dynamic describeUnique(EventCondition c);
}

abstract class EventCondition {
  const EventCondition();
}

abstract class EventData {
  const EventData();
}

class _DefaultEventStreamsTable extends EventStreamsTable {
  _DefaultEventStreamsTable(super.rootStream, this.conditions) {
    _rootEvents = rootStream.listen((e) {
      final key = _transformers.isNotEmpty
          ? conditions.processEvent(_transformers.fold(e, (ev, fn) => fn(ev)))
          : conditions.processEvent(e);

      _map[key]?.add(null);
    });
  }

  @override
  final Conditions conditions;

  late final StreamSubscription<EventData> _rootEvents;

  final _transformers = <EventData Function(EventData p1)>[];
  final _map = <dynamic, StreamController<void>>{};

  @override
  bool hasListeners(EventCondition c) =>
      _map.containsKey(conditions.describeUnique(c));

  @override
  void addTransformer(EventData Function(EventData p1) f) {
    _transformers.add(f);
  }

  @override
  void removeTransformer(EventData Function(EventData p1) f) {
    _transformers.removeWhere((e) => f == e);
  }

  @override
  Stream<void> forCondition(EventCondition c, [bool fire = false]) {
    if (!conditions.isOfThis(c)) {
      throw "expected $c to be of $conditions";
    }
    final key = conditions.describeUnique(c);

    final e = _map.putIfAbsent(
      key,
      () => StreamController.broadcast(
        onCancel: () {
          _map.remove(key)?.close();
        },
      ),
    );

    final ret = StreamController<void>();

    if (fire) {
      ret.add(null);
    }

    ret.addStream(e.stream);
    return ret.stream;
  }

  @override
  void clear() {
    for (final e in _map.values) {
      e.close();
    }
    _map.clear();
  }

  @override
  void destroy() {
    _rootEvents.cancel();
    clear();
  }
}
