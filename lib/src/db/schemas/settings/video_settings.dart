// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/initalize_db.dart";
import "package:isar/isar.dart";

part "video_settings.g.dart";

@collection
class VideoSettings {
  const VideoSettings({required this.looping, required this.volume});

  Id get id => 0;

  final bool looping;
  final double volume;

  VideoSettings copy({bool? looping, double? volume}) => VideoSettings(
        looping: looping ?? this.looping,
        volume: volume ?? this.volume,
      );

  static VideoSettings get current =>
      Dbs.g.main.videoSettings.getSync(0) ??
      const VideoSettings(looping: true, volume: 1);

  static void changeVolume(double volume) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.videoSettings.putSync(current.copy(volume: volume)),
    );
  }

  static void changeLooping(bool looping) {
    Dbs.g.main.writeTxnSync(
      () => Dbs.g.main.videoSettings.putSync(current.copy(looping: looping)),
    );
  }
}
