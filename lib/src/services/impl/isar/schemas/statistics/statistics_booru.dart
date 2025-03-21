// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/services.dart";
import "package:isar/isar.dart";

part "statistics_booru.g.dart";

@collection
class IsarStatisticsBooru extends StatisticsBooruData {
  const IsarStatisticsBooru({
    required super.booruSwitches,
    required super.downloaded,
    required super.swiped,
    required super.viewed,
  });

  Id get id => 0;

  @override
  IsarStatisticsBooru add({
    int? viewed,
    int? downloaded,
    int? swiped,
    int? booruSwitches,
  }) =>
      IsarStatisticsBooru(
        booruSwitches: this.booruSwitches + (booruSwitches ?? 0),
        downloaded: this.downloaded + (downloaded ?? 0),
        swiped: this.swiped + (swiped ?? 0),
        viewed: this.viewed + (viewed ?? 0),
      );
}
