// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/db/services/services.dart";
import "package:isar/isar.dart";

part "statistics_general.g.dart";

@collection
class IsarStatisticsGeneral extends StatisticsGeneralData {
  const IsarStatisticsGeneral({
    required super.refreshes,
    required super.scrolledUp,
    required super.timeDownload,
    required super.timeSpent,
  });

  Id get id => 0;

  @override
  IsarStatisticsGeneral add({
    int? timeSpent,
    int? timeDownload,
    int? scrolledUp,
    int? refreshes,
  }) =>
      IsarStatisticsGeneral(
        refreshes: this.refreshes + (refreshes ?? 0),
        scrolledUp: this.scrolledUp + (scrolledUp ?? 0),
        timeDownload: this.timeDownload + (timeDownload ?? 0),
        timeSpent: this.timeSpent + (timeSpent ?? 0),
      );
}
