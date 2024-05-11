// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension VideoSettingsDataExt on VideoSettingsData {
  void save() => _currentDb.videoSettings.add(this);
}

abstract class VideoSettingsData {
  const VideoSettingsData({
    required this.looping,
    required this.volume,
  });

  final bool looping;
  final double volume;

  VideoSettingsData copy({bool? looping, double? volume});
}

mixin VideoSettingsDbScope<W extends DbConnHandle<VideoSettingsService>>
    implements DbScope<VideoSettingsService, W>, VideoSettingsService {
  @override
  VideoSettingsData get current => widget.db.current;

  @override
  void add(VideoSettingsData data) => widget.db.add(data);
}

abstract interface class VideoSettingsService implements ServiceMarker {
  VideoSettingsData get current;

  void add(VideoSettingsData data);
}
