// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:isar/isar.dart";

part "video_settings.g.dart";

@collection
class IsarVideoSettings extends VideoSettingsData {
  const IsarVideoSettings({
    required super.looping,
    required super.volume,
  });

  Id get id => 0;

  @override
  VideoSettingsData copy({bool? looping, double? volume}) => IsarVideoSettings(
        looping: looping ?? this.looping,
        volume: volume ?? this.volume,
      );
}
