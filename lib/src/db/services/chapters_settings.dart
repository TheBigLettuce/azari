// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension ChaptersSettingsDataExt on ChaptersSettingsData {
  void save() => _currentDb.chaptersSettings.add(this);
}

abstract class ChaptersSettingsData {
  const ChaptersSettingsData({
    required this.hideRead,
  });

  final bool hideRead;

  ChaptersSettingsData copy({
    bool? hideRead,
  });
}

abstract interface class ChaptersSettingsService implements ServiceMarker {
  ChaptersSettingsData get current;

  void add(ChaptersSettingsData data);

  StreamSubscription<ChaptersSettingsData?> watch(
    void Function(ChaptersSettingsData? c) f,
  );
}
