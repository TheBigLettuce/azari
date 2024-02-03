// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/widgets/empty_widget.dart';

enum LogSeverity {
  init(1),
  trace(400),
  important(1000);

  final int value;

  const LogSeverity(this.value);
}

enum LogTarget {
  init,
  downloader,
  unknown,
  booru,
  gallery,
  anime;

  void logDefault(LogMessage message,
      [LogSeverity severity = LogSeverity.trace, StackTrace? stackTrace]) {
    final f = getLogger();

    f.add(this, severity, message, stackTrace ?? StackTrace.current);
  }

  void logDefaultImportant(LogMessage message, StackTrace stackTrace) =>
      logDefault(message, LogSeverity.important, stackTrace);
}

class _DummyLogger implements LoggingInterface {
  const _DummyLogger();

  @override
  void add(LogTarget target, LogSeverity severity, LogMessage message,
      StackTrace stackTrace) {}

  @override
  LogStorage get storage => const _DummyLoggerStorage();
}

class _DummyLoggerStorage implements LogStorage {
  @override
  LogRecord load(LogTarget t, LogSeverity severity, int id) {
    return LogRecord("", t, severity, "");
  }

  @override
  int save(LogRecord r) {
    return 0;
  }

  @override
  StreamSubscription<void> watch(void Function(void p1) f) {
    return const _DummyStreamSubscription();
  }

  const _DummyLoggerStorage();
}

class _DummyStreamSubscription implements StreamSubscription<void> {
  const _DummyStreamSubscription();

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    return Future.value(futureValue);
  }

  @override
  Future<void> cancel() {
    return Future.value();
  }

  @override
  bool get isPaused => false;

  @override
  void onData(void Function(void data)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}
}

late final LoggingInterface _current;

class _PrintLoggerStorage implements LogStorage {
  final List<LogRecord> _buffer = [];
  final StreamController<void> _controller = StreamController();
  late final Stream _events;

  @override
  LogRecord load(LogTarget t, LogSeverity severity, int id) {
    return _buffer[id];
  }

  @override
  int save(LogRecord r) {
    if (_buffer.length >= 50) {
      _buffer.removeAt(0);
    }

    _buffer.add(r);
    log(r.formatTerminal(),
        level: r.severity.value,
        stackTrace: r.severity == LogSeverity.important
            ? StackTrace.fromString(r.stackTrace)
            : null);
    _controller.sink.add(null);

    return _buffer.length - 1;
  }

  @override
  StreamSubscription<void> watch(void Function(void) f) {
    return _events.listen(f);
  }

  _PrintLoggerStorage() {
    _events = _controller.stream.asBroadcastStream();
  }
}

class _PrintLogger implements LoggingInterface {
  final _storage = _PrintLoggerStorage();

  @override
  void add(LogTarget target, LogSeverity severity, LogMessage message,
          StackTrace stackTrace) =>
      message.resolve(target, severity, storage, stackTrace);

  @override
  LogStorage get storage => _storage;

  _PrintLogger();
}

void initLogger() {
  if (kDebugMode) {
    _current = _PrintLogger();
    LogTarget.init.logDefault("Logger(print)".messageInit, LogSeverity.init);
  } else {
    _current = const _DummyLogger();
    LogTarget.init.logDefault("Logger(dummy)".messageInit, LogSeverity.init);

    FlutterError.onError = (details) {
      LogTarget.unknown.logDefaultImportant(
          details.exception.toString().message,
          details.stack ?? StackTrace.current);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      LogTarget.unknown.logDefaultImportant(error.toString().message, stack);

      return true;
    };
  }
}

LoggingInterface getLogger() => _current;

abstract class LoggingInterface {
  void add(LogTarget target, LogSeverity severity, LogMessage message,
      StackTrace stackTrace);

  LogStorage get storage;
}

abstract class LogStorage {
  LogRecord load(LogTarget t, LogSeverity severity, int id);
  int save(LogRecord r);

  StreamSubscription<void> watch(void Function(void) f);
}

class LogRecord {
  final String value;
  final LogTarget target;
  final LogSeverity severity;
  final String stackTrace;

  String formatTerminal() {
    return "${target.name}(${severity.name}): $value";
  }

  LogRecord(this.value, this.target, this.severity, this.stackTrace);
}

abstract class LogMessage {
  void resolve(LogTarget target, LogSeverity severity, LogStorage s,
      StackTrace stackTrace);
}

extension StringLogMessage on String {
  LogMessage get message => _StringLogMessage(this);
  LogMessage get messageInit => _StringLogMessage("$this initalized");

  LogMessage networkMessage(int? statusCode, String? addInfo) =>
      _StringLogMessage("$this req: result — $statusCode, $addInfo");

  LogMessage errorMessage(Object? error) =>
      _StringLogMessage("$this e: $error");
}

class _StringLogMessage implements LogMessage {
  final String value;

  @override
  void resolve(LogTarget target, LogSeverity severity, LogStorage s,
          StackTrace stackTrace) =>
      s.save(LogRecord(value, target, severity, stackTrace.toString()));

  const _StringLogMessage(this.value);
}

class LogReq {
  const LogReq(this.message, this.target);

  final LogTarget target;
  final String message;

  static String notes(Booru booru, int postId) =>
      "notes $postId (${booru.string})";
  static String completeTag(Booru booru, String str) =>
      "complete tag $str (${booru.string})";
  static String singlePost(Booru booru, int postId) =>
      "single post $postId (${booru.string})";
  static String page(Booru booru, int page) => "page $page (${booru.string})";
  static String fromPost(Booru booru, int postId) =>
      "from post $postId (${booru.string})";
}

extension ReqLoggingExt on Dio {
  Future<Response<T>> getUriLog<T>(
    Uri uri,
    LogReq rdata, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final result = await getUri<T>(
        uri,
        data: data,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      rdata.target.logDefault(rdata.message
          .networkMessage(result.statusCode, result.statusMessage));

      return result;
    } catch (e, stack) {
      rdata.target.logDefaultImportant(
          rdata.message.errorMessage(EmptyWidget.unwrapDioError(e)), stack);
      rethrow;
    }
  }
}
