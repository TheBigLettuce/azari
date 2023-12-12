// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:gallery/src/db/initalize_db.dart';
import 'package:isar/isar.dart';

part 'statistics_general.g.dart';

@collection
class StatisticsGeneral {
  final Id id = 0;

  final int timeSpent;
  final int timeDownload;
  final int scrolledUp;
  final int refreshes;

  const StatisticsGeneral(
      {required this.refreshes,
      required this.scrolledUp,
      required this.timeDownload,
      required this.timeSpent});

  StatisticsGeneral copy({
    int? timeSpent,
    int? timeDownload,
    int? scrolledUp,
    int? refreshes,
  }) =>
      StatisticsGeneral(
          refreshes: refreshes ?? this.refreshes,
          scrolledUp: scrolledUp ?? this.scrolledUp,
          timeDownload: timeDownload ?? this.timeDownload,
          timeSpent: timeSpent ?? this.timeSpent);

  const StatisticsGeneral.empty()
      : timeDownload = 0,
        timeSpent = 0,
        scrolledUp = 0,
        refreshes = 0;

  static StatisticsGeneral get current =>
      Dbs.g.main.statisticsGenerals.getSync(0) ??
      const StatisticsGeneral.empty();

  static void addTimeSpent(int time) {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGenerals
        .putSync(c.copy(timeSpent: c.timeSpent + time)));
  }

  static void addTimeDownload(int time) {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGenerals
        .putSync(c.copy(timeDownload: c.timeDownload + time)));
  }

  static void addScrolledUp() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGenerals
        .putSync(c.copy(scrolledUp: c.scrolledUp + 1)));
  }

  static void addRefreshes() {
    final c = current;

    Dbs.g.main.writeTxnSync(() => Dbs.g.main.statisticsGenerals
        .putSync(c.copy(refreshes: c.refreshes + 1)));
  }
}
