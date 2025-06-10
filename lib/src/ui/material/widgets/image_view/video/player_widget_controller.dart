// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:meta/meta.dart";

abstract class PlayerWidgetController {
  factory PlayerWidgetController() = _VideoPlayerControllerImpl;

  Stream<PlayerButtonEvent> get buttonEvents;
  Stream<PlayerEvent> get playerEvents;

  Duration? get duration;
  Duration? get progress;
  PlayState? get playState;
  double? get volume;

  set duration(Duration? d);
  set progress(Duration? p);
  set playState(PlayState? s);
  set volume(double? v);

  void addButtonEvent(PlayerButtonEvent e);

  void clear();

  void dispose();
}

sealed class PlayerButtonEvent {
  const PlayerButtonEvent();
}

enum PlayState { isPlaying, buffering, stopped }

class VolumeButton implements PlayerButtonEvent {
  const VolumeButton();
}

class FullscreenButton implements PlayerButtonEvent {
  const FullscreenButton();
}

class PlayButton implements PlayerButtonEvent {
  const PlayButton();
}

class LoopingButton implements PlayerButtonEvent {
  const LoopingButton();
}

class AddDuration implements PlayerButtonEvent {
  const AddDuration(this.durationSeconds);

  final double durationSeconds;
}

@immutable
sealed class PlayerEvent {
  const PlayerEvent();
}

class DurationUpdate extends PlayerEvent {
  const DurationUpdate(this.duration);

  final Duration duration;
}

class ProgressUpdate extends PlayerEvent {
  const ProgressUpdate(this.progress);

  final Duration progress;
}

class PlayStateUpdate extends PlayerEvent {
  const PlayStateUpdate(this.playState);

  final PlayState playState;
}

class VolumeUpdate extends PlayerEvent {
  const VolumeUpdate(this.volume);

  final double volume;
}

class ClearUpdate extends PlayerEvent {
  const ClearUpdate();
}

class _VideoPlayerControllerImpl implements PlayerWidgetController {
  _VideoPlayerControllerImpl();

  final _events = StreamController<PlayerButtonEvent>.broadcast();
  final _playerEvents = StreamController<PlayerEvent>.broadcast();

  @override
  Duration? get duration => _duration;
  @override
  Duration? get progress => _progress;
  @override
  PlayState? get playState => _playState;
  @override
  double? get volume => _volume;

  @override
  set duration(Duration? d) {
    if (d != duration && d != null) {
      _duration = d;
      _playerEvents.add(DurationUpdate(d));
    }
  }

  @override
  set progress(Duration? p) {
    if (p != progress && p != null) {
      _progress = p;
      _playerEvents.add(ProgressUpdate(p));
    }
  }

  @override
  set playState(PlayState? p) {
    if (p != playState && p != null) {
      _playState = p;
      _playerEvents.add(PlayStateUpdate(p));
    }
  }

  @override
  set volume(double? v) {
    if (v != volume && v != null) {
      _volume = v;
      _playerEvents.add(VolumeUpdate(v));
    }
  }

  Duration? _duration;
  Duration? _progress;
  PlayState? _playState;
  double? _volume;

  @override
  Stream<PlayerButtonEvent> get buttonEvents => _events.stream;

  @override
  Stream<PlayerEvent> get playerEvents => _playerEvents.stream;

  @override
  void dispose() {
    _events.close();
    _playerEvents.close();
  }

  @override
  void clear() {
    duration = null;
    progress = null;
    playState = null;

    _playerEvents.add(const ClearUpdate());
  }

  @override
  void addButtonEvent(PlayerButtonEvent e) => _events.add(e);
}
