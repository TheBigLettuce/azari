// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'cell_loader.dart';

class BinaryLoaderStateController<T extends Cell>
    implements LoaderStateController {
  final Stream _events;
  final void Function(BinaryLoaderStateController<T>) onNext;
  final void Function(BinaryLoaderStateController<T>) onReset;

  LoaderState _state = LoaderState.idle;
  StreamSubscription? _currentSubscription;

  @override
  LoaderState get currentState => _state;

  @mustCallSuper
  @override
  void listen(f) {
    if (_currentSubscription != null) {
      _currentSubscription?.cancel();
    }

    _currentSubscription = _events.listen((event) {
      if (event is Poll) {
        f();

        return;
      }

      event as LoaderState;

      if (event == currentState) {
        return;
      }

      _state = event;

      f();
    });
  }

  @mustCallSuper
  @override
  void next() {
    if (currentState == LoaderState.idle) {
      onNext(this);
    }
  }

  @mustCallSuper
  @override
  void reset() {
    if (currentState == LoaderState.idle) {
      onReset(this);
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    _currentSubscription?.cancel();
  }

  static void _doNothing(BinaryLoaderStateController _) {}

  BinaryLoaderStateController(BackgroundCellLoader<T> loader,
      {this.onNext = _doNothing, this.onReset = _doNothing})
      : _events = loader._isolateEvents;
}
