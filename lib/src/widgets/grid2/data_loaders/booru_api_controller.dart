// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'cell_loader.dart';

class BooruAPILoaderStateController implements LoaderStateController {
  final Stream _events;
  final SendPort _send;

  final BooruAPIState api;
  final BooruTagging excluded;
  final String tags;

  final void Function(BooruAPIState) onPostsLoaded;

  LoaderState _state = LoaderState.idle;
  StreamSubscription? _currentSubscription;
  void Function()? _notify;

  int? currentLast;

  bool end = false;

  static void _doNothing(BooruAPIState _) {}

  BooruAPILoaderStateController(
    BackgroundCellLoader<Post> loader,
    this.api,
    this.excluded,
    this.tags,
    int? lastId, {
    this.onPostsLoaded = _doNothing,
  })  : _events = loader._isolateEvents,
        currentLast = lastId,
        _send = loader._send;

  void _stateChange(LoaderState s) {
    _state = s;
    currentLast = null;
    _notify?.call();
  }

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

    _notify = f;
  }

  void _sendPosts((List<Post>, int?) value) {
    final last = value.$1.lastOrNull;
    if (last == null) {
      _stateChange(LoaderState.idle);
      end = true;
      return;
    }

    if (value.$2 != null) {
      if (value.$2! < last.id) {
        currentLast = value.$2;
      } else {
        currentLast = last.id;
      }
    } else {
      currentLast = last.id;
    }

    _send.send(Data<Post>(value.$1, end: true));

    onPostsLoaded(api);
  }

  @mustCallSuper
  @override
  void next() {
    if (end) {
      return;
    }

    if (currentState == LoaderState.idle && _currentSubscription != null) {
      final last = currentLast;

      _stateChange(LoaderState.loading);

      api.fromPost(last!, tags, excluded).then(_sendPosts);
    }
  }

  @mustCallSuper
  @override
  void reset() {
    if (currentState == LoaderState.idle && _currentSubscription != null) {
      _stateChange(LoaderState.loading);
      _send.send(const Reset(true));
      end = false;
      api.page(0, tags, excluded).then(_sendPosts);
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    _currentSubscription?.cancel();
    _currentSubscription = null;
    _notify = null;
    // currentLast = null;
    // end = false;
    // api.close();
  }
}
