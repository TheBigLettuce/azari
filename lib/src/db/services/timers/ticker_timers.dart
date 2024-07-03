// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:isolate";

import "package:flutter/material.dart";
import "package:gallery/src/db/services/timers/timers.dart";

class TickerTimers implements Timers {
  TickerTimers();

  static void _isolateMain(SendPort port) {}

  Isolate? _isolate;
  late final Stream<dynamic> _events;

  final ReceivePort _port = ReceivePort("TickerTimers _port");
  late final SendPort _controlPort;

  late final _TickerTimerWorld _world;

  Future<void> init() async {
    if (_isolate != null) {
      return;
    }

    _isolate = await Isolate.spawn(
      _isolateMain,
      _port.sendPort,
      errorsAreFatal: false,
    );

    _events = _port.asBroadcastStream();
    _controlPort = _events.first as SendPort;

    _world = _TickerTimerWorld(_events, _controlPort);
  }

  @override
  void register(PeriodicalTimer t) {
    // TODO: implement register
  }

  @override
  Stream<TimerTaskResult<T>> eventsTask<T extends TimerProgress>(
    String backupKey,
  ) {
    // TODO: implement eventsTask
    throw UnimplementedError();
  }

  @override
  TimerTaskResult<T> getTaskResult<T extends TimerProgress>(String backupKey) {
    // TODO: implement getTaskResult
    throw UnimplementedError();
  }

  @override
  T getTimerData<T extends TimerProgress>(String backupKey) {
    // TODO: implement getTimerData
    throw UnimplementedError();
  }
}

class _TickerTimerWorld implements TimerWorld {
  _TickerTimerWorld(
    this._events,
    this._controlPort,
  ) {
    _events.listen((data) {
      final data_ = data as _IsolateEventsRecv;

      switch (data_) {
        case _FutureResultEvent():
          final v = results[data_.key]!;

          results[data_.key] = _CurrentTaskData(
            v.events,
            (
              null,
              data_.value,
              data_.date,
              data_.restartCount,
            ),
          );
        case _FutureResultErrorEvent():
        // TODO: Handle this case.
      }
    });
  }

  final Map<String, _CurrentTaskData> results = {};

  final Stream<dynamic> _events;
  final SendPort _controlPort;

  @override
  Stream<TimerTaskResult<T>> eventsForTimer<T extends TimerProgress>(
    String backupKey,
  ) =>
      results[backupKey]!.events as Stream<TimerTaskResult<T>>;

  @override
  TimerTaskResult<T> readTaskResult<T extends TimerProgress>(
    String backupKey, {
    bool allowRestart = false,
  }) {
    final r = results[backupKey]?.lastResult;
    if (r == null) {
      return _TaskResult(
        DateTime.now(),
        null,
        null,
        const UnregistredTaskError(),
        0,
      );
    }

    return _TaskResult(
      r.$3,
      allowRestart ? () {} : null,
      r.$2 as T?,
      r.$2 == null ? const TaskInProgressError() : r.$1,
      r.$4,
    );
  }

  @override
  void registerFuture<T>(
    String backupKey,
    FutureRequest req, {
    bool retryOnError = true,
    T Function()? onError,
  }) =>
      _controlPort.send(_RegisterFutureEvent(backupKey, req, retryOnError));
}

class _TaskResult<T extends TimerProgress> implements TimerTaskResult<T> {
  const _TaskResult(
    this.date,
    this._schedule,
    this._value,
    this.error,
    this.restartCount,
  );

  final void Function()? _schedule;

  final T? _value;

  @override
  final DateTime date;

  @override
  final Object? error;

  @override
  final int restartCount;

  @override
  bool get hasError => error != null;

  @override
  bool get hasValue => _value != null;

  @override
  T get value => _value!;

  @override
  void scheduleRestartAtOnce() => _schedule?.call();
}

class _CurrentTaskData {
  _CurrentTaskData(this.events, this.lastResult);

  final Stream<TimerTaskResult> events;
  final (Object?, dynamic, DateTime, int) lastResult;
}

@immutable
sealed class _IsolateEventsSend {}

sealed class _IsolateEventsRecv {}

@immutable
class _RegisterFutureEvent implements _IsolateEventsSend {
  const _RegisterFutureEvent(this.backupKey, this.req, this.retry);

  final String backupKey;
  final FutureRequest req;
  final bool retry;
}

class _FutureResultEvent implements _IsolateEventsRecv {
  const _FutureResultEvent(this.key, this.value, this.date, this.restartCount);

  final String key;
  final dynamic value;
  final DateTime date;
  final int restartCount;
}

class _FutureResultErrorEvent implements _IsolateEventsRecv {
  const _FutureResultErrorEvent(
    this.key,
    this.value,
    this.date,
    this.restartCount,
  );

  final String key;
  final dynamic value;
  final DateTime date;
  final int restartCount;
}

class UnregistredTaskError implements Exception {
  const UnregistredTaskError();
}

class TaskInProgressError implements Exception {
  const TaskInProgressError();
}
