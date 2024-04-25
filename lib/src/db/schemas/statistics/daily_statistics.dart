// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../../initalize_db.dart';

part 'daily_statistics.g.dart';

@collection
class DailyStatistics {
  final Id id = 0;

  final int swipedBoth;
  final int durationMillis;

  final DateTime date;

  const DailyStatistics({
    required this.swipedBoth,
    required this.durationMillis,
    required this.date,
  });

  DailyStatistics copy({
    int? durationMillis,
    int? swipedBoth,
    DateTime? date,
  }) =>
      DailyStatistics(
        durationMillis: durationMillis ?? this.durationMillis,
        date: date ?? this.date,
        swipedBoth: swipedBoth ?? this.swipedBoth,
      );

  DailyStatistics add({required int swipedBoth}) => DailyStatistics(
        durationMillis: durationMillis,
        date: date,
        swipedBoth: swipedBoth + this.swipedBoth,
      );

  static DailyStatistics get current =>
      Dbs.g.main.dailyStatistics.getSync(0) ??
      DailyStatistics(
        swipedBoth: 0,
        date: DateTime.now(),
        durationMillis: 0,
      );

  void save() {
    Dbs.g.main.writeTxnSync(() => Dbs.g.main.dailyStatistics.putSync(this));
  }
}
