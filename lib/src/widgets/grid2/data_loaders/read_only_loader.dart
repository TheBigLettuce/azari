// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';
import 'dart:isolate';

import 'package:gallery/src/interfaces/background_data_loader/background_data_loader.dart';
import 'package:isar/isar.dart';

import '../../../interfaces/background_data_loader/control_message.dart';
import '../../../interfaces/background_data_loader/data_transformer.dart';
import '../../../interfaces/background_data_loader/loader_state_controller.dart';
import 'dummy_controller.dart';

class ReadOnlyDataLoader<T> implements BackgroundDataLoader<T> {
  final Isar _instance;
  final T? Function(Isar) _getCell;

  StreamSubscription<void>? _subscription;

  void Function(int p1)? _notify;

  @override
  late final DataTransformer<T>? transformer;

  ReadOnlyDataLoader(this._instance, this._getCell,
      {DataTransformer<T> Function(ReadOnlyDataLoader<T>)? makeTransformer}) {
    transformer = makeTransformer?.call(this);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notify = null;
    _subscription = null;
  }

  @override
  T? getSingle(int token) {
    final cell = _getCell(_instance);
    if (cell == null) {
      return null;
    }

    return transformer != null ? transformer!.transformCell(cell) : cell;
  }

  @override
  Future<void> init() => Future.value();

  @override
  Isolate get isolate => throw UnimplementedError();

  @override
  void listenStatus(void Function(int p1) f) {
    _subscription?.cancel();
    _notify = f;

    _instance.collection<T>().watchLazy(fireImmediately: true).listen((event) {
      _listenStatusCallback(f);
      // f(_instance.collection<ID, T>().count());
    });
  }

  void _listenStatusCallback(void Function(int p1) f) {
    if (transformer != null) {
      transformer!.transformStatusCallback((count) {
        f(count);
      });
    } else {
      f(_instance.collection<T>().countSync());
    }
  }

  @override
  void send(ControlMessage m) {
    if (m is Poll) {
      if (_notify != null) {
        _listenStatusCallback(_notify!);
      }
    }
    assert(false, ".send on ReadOnlyDataLoader should not be used");
  }

  @override
  LoaderStateController get state => const DummyLoaderStateController();
}
