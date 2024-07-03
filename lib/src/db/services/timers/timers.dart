// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

abstract interface class Timers {
  void register(PeriodicalTimer t);

  T getTimerData<T extends TimerProgress>(String backupKey);
  TimerTaskResult<T> getTaskResult<T extends TimerProgress>(String backupKey);

  Stream<TimerTaskResult<T>> eventsTask<T extends TimerProgress>(
    String backupKey,
  );
}

abstract interface class TimerWorld {
  void registerFuture<T>(
    String backupKey,
    FutureRequest req, {
    bool retryOnError = true,
    T Function()? onError,
  });

  TimerTaskResult<T> readTaskResult<T extends TimerProgress>(
    String backupKey, {
    bool allowRestart = false,
  });

  Stream<TimerTaskResult<T>> eventsForTimer<T extends TimerProgress>(
    String backupKey,
  );
}

@immutable
abstract class FutureRequest {
  Future<dynamic> load();
}

abstract class TimerTaskResult<T extends TimerProgress> {
  bool get hasError;
  Object? get error;

  bool get hasValue;
  T get value;

  int get restartCount;

  DateTime get date;

  void scheduleRestartAtOnce();
}

class PeriodicalTimer<T extends TimerBackup> {
  const PeriodicalTimer(
    this.instance,
    this.waitLength,
  );

  final T instance;

  final Duration waitLength;
}

abstract interface class TimerBackup {
  void runTask(TimerWorld world);

  String get backupKey;

  PeriodicalTimer<T> fromBackup<T extends TimerBackup>(
    String backupKey,
    dynamic progressJson,
  );
}

abstract class TimerProgress {
  dynamic toJson();
}
