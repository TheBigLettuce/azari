// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsDailyDataExt on StatisticsDailyData {
  void save() => _currentDb.statisticsDaily.add(this);
}

abstract class StatisticsDailyData {
  const StatisticsDailyData({
    required this.swipedBoth,
    required this.durationMillis,
    required this.date,
  });

  final int swipedBoth;
  final int durationMillis;

  final DateTime date;

  StatisticsDailyData copy({
    int? durationMillis,
    int? swipedBoth,
    DateTime? date,
  });

  StatisticsDailyData add({required int swipedBoth});
}

abstract interface class StatisticsDailyService implements ServiceMarker {
  factory StatisticsDailyService.db() => _currentDb.statisticsDaily;

  StatisticsDailyData get current;

  void add(StatisticsDailyData data);
}
