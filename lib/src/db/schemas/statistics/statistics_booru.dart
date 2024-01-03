// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../../initalize_db.dart';

part 'statistics_booru.g.dart';

@collection
class StatisticsBooru {
  final Id id = 0;

  final int viewed;
  final int downloaded;
  final int swiped;
  final int booruSwitches;

  const StatisticsBooru(
      {required this.booruSwitches,
      required this.downloaded,
      required this.swiped,
      required this.viewed});

  StatisticsBooru copy({
    int? viewed,
    int? downloaded,
    int? swiped,
    int? booruSwitches,
  }) =>
      StatisticsBooru(
          booruSwitches: booruSwitches ?? this.booruSwitches,
          downloaded: downloaded ?? this.downloaded,
          swiped: swiped ?? this.swiped,
          viewed: viewed ?? this.viewed);

  const StatisticsBooru.empty()
      : viewed = 0,
        downloaded = 0,
        swiped = 0,
        booruSwitches = 0;

  static StatisticsBooru get current =>
      Dbs.g.main.statisticsBoorus.getSync(0) ?? const StatisticsBooru.empty();

  static void addViewed() {
    final c = current;

    Dbs.g.main.writeTxnSync(() =>
        Dbs.g.main.statisticsBoorus.putSync(c.copy(viewed: c.viewed + 1)));
  }

  static void addDownloaded() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsBoorus
        .putSync(c.copy(downloaded: c.downloaded + 1)));
  }

  static void addSwiped() {
    final c = current;

    Dbs.g.main.writeTxnSync(() =>
        Dbs.g.main.statisticsBoorus.putSync(c.copy(swiped: c.swiped + 1)));
  }

  static void addBooruSwitches() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsBoorus
        .putSync(c.copy(booruSwitches: c.booruSwitches + 1)));
  }
}
