// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsGeneralDataExt on StatisticsGeneralData {
  void save() => _currentDb.statisticsGeneral.add(this);
}

abstract class StatisticsGeneralData {
  const StatisticsGeneralData({
    required this.refreshes,
    required this.scrolledUp,
    required this.timeDownload,
    required this.timeSpent,
  });

  final int timeSpent;
  final int timeDownload;
  final int scrolledUp;
  final int refreshes;

  StatisticsGeneralData add({
    int? timeSpent,
    int? timeDownload,
    int? scrolledUp,
    int? refreshes,
  });
}

abstract interface class StatisticsGeneralService implements ServiceMarker {
  factory StatisticsGeneralService.db() => _currentDb.statisticsGeneral;

  StatisticsGeneralData get current;

  void add(StatisticsGeneralData data);
}
