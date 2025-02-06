// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:isolate";

import "package:flutter/foundation.dart";

abstract class IsolateIO<I, O> {
  void send(I i);

  Stream<O> get events;
}

abstract class IsolateLoop<Data> {
  IsolateLoop(String debugName) : _debugName = debugName;

  final _port = ReceivePort();
  late final Isolate _isolate;
  late final Stream<dynamic> _stream;
  late final StreamSubscription<dynamic> _events;
  late final SendPort _sendPort;

  final String _debugName;

  bool _isInit = false;
  bool _isDisposed = false;

  Future<void> init(Data data) {
    if (_isInit) {
      return Future.value();
    }
    _isInit = true;

    return _init(data);
  }

  Future<void> _init(Data data) async {
    _stream = _port.asBroadcastStream();

    final (port, isolate) = await (
      _stream.first,
      Isolate.spawn(
        makeMain(),
        (data: data, port: _port.sendPort),
        errorsAreFatal: false,
        debugName: _debugName,
      ),
    ).wait;

    _isolate = isolate;
    _sendPort = port as SendPort;
    _events = _stream.listen(onEvent);
  }

  Future<void> Function(({Data data, SendPort port}) data) makeMain();

  void sendMessage(dynamic e) {
    _sendPort.send(e);
  }

  void onEvent(dynamic e);

  void destroy() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    _events.cancel();
    _port.close();
    _isolate.kill();
  }
}

class IsolateManagement {
  IsolateManagement(this.port);

  final SendPort port;
  late final ReceivePort receivePort;

  bool _isInit = false;

  Future<void> init() {
    if (_isInit) {
      return Future.value();
    }
    _isInit = true;

    receivePort = ReceivePort();

    port.send(receivePort.sendPort);

    return Future.value();
  }

  Future<T?> runCatching<T>(Future<T> Function() f) {
    try {
      return f();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }

      return Future.value();
    }
  }

  Future<void> listen(void Function(dynamic) f) async {
    await for (final e in receivePort) {
      f(e);
    }
  }

  void destroy() {
    receivePort.close();
    Isolate.current.kill();
  }
}
