// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:meta/meta.dart";

abstract class VideoControlsController {
  void setDuration(Duration d);
  void setProgress(Duration p);
  void setPlayState(PlayState p);
  void setVolume(double volume);

  void clear();

  Stream<VideoControlsEvent> get events;
}

sealed class VideoControlsEvent {
  const VideoControlsEvent();
}

enum PlayState {
  isPlaying,
  buffering,
  stopped;
}

class VolumeButton implements VideoControlsEvent {
  const VolumeButton();
}

class FullscreenButton implements VideoControlsEvent {
  const FullscreenButton();
}

class PlayButton implements VideoControlsEvent {
  const PlayButton();
}

class LoopingButton implements VideoControlsEvent {
  const LoopingButton();
}

class AddDuration implements VideoControlsEvent {
  const AddDuration(this.durationSeconds);

  final double durationSeconds;
}

@immutable
sealed class PlayerUpdate {
  const PlayerUpdate();
}

class DurationUpdate extends PlayerUpdate {
  const DurationUpdate(this.duration);

  final Duration duration;
}

class ProgressUpdate extends PlayerUpdate {
  const ProgressUpdate(this.progress);

  final Duration progress;
}

class PlayStateUpdate extends PlayerUpdate {
  const PlayStateUpdate(this.playState);

  final PlayState playState;
}

class VolumeUpdate extends PlayerUpdate {
  const VolumeUpdate(this.volume);

  final double volume;
}

class ClearUpdate extends PlayerUpdate {
  const ClearUpdate();
}
