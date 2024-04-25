// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:gallery/src/db/initalize_db.dart";
import "package:isar/isar.dart";

part "chapters_settings.g.dart";

@collection
class ChapterSettings {
  const ChapterSettings({
    required this.hideRead,
  });

  Id get isarId => 0;

  final bool hideRead;

  ChapterSettings copy({
    bool? hideRead,
  }) {
    return ChapterSettings(
      hideRead: hideRead ?? this.hideRead,
    );
  }

  static ChapterSettings get current =>
      Dbs.g.anime.chapterSettings.getSync(0) ??
      const ChapterSettings(hideRead: false);

  static void setHideRead(bool read) {
    Dbs.g.anime.writeTxnSync(
      () => Dbs.g.anime.chapterSettings.putSync(
        current.copy(hideRead: read),
      ),
    );
  }

  static StreamSubscription<ChapterSettings?> watch(
    void Function(ChapterSettings? c) f,
  ) {
    return Dbs.g.anime.chapterSettings.watchObject(0).listen(f);
  }
}
