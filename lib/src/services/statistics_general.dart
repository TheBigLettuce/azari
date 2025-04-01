// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

extension StatisticsGeneralDataExt on StatisticsGeneralData {
  void maybeSave() => _dbInstance.get<StatisticsGeneralService>()?.add(this);
}

abstract interface class StatisticsGeneralService implements ServiceMarker {
  StatisticsGeneralData get current;

  void add(StatisticsGeneralData data);

  StreamSubscription<StatisticsGeneralData> watch(
    void Function(StatisticsGeneralData d) f, [
    bool fire = false,
  ]);

  static void addTimeSpent(int t) {
    _dbInstance
        .get<StatisticsGeneralService>()
        ?.current
        .add(timeSpent: t)
        .maybeSave();
  }

  static void addTimeDownload(int t) {
    _dbInstance
        .get<StatisticsGeneralService>()
        ?.current
        .add(timeDownload: t)
        .maybeSave();
  }

  static void addScrolledUp(int s) {
    _dbInstance
        .get<StatisticsGeneralService>()
        ?.current
        .add(scrolledUp: s)
        .maybeSave();
  }

  static void addRefreshes(int r) {
    _dbInstance
        .get<StatisticsGeneralService>()
        ?.current
        .add(refreshes: r)
        .maybeSave();
  }
}

mixin StatisticsGeneralWatcherMixin<S extends StatefulWidget> on State<S> {
  StatisticsGeneralService get statisticsGeneralService;

  StreamSubscription<StatisticsGeneralData>? _statisticsGeneralEvents;

  late StatisticsGeneralData statisticsGeneral;

  @override
  void initState() {
    super.initState();

    statisticsGeneral = statisticsGeneralService.current;

    _statisticsGeneralEvents?.cancel();
    _statisticsGeneralEvents = statisticsGeneralService.watch((newSettings) {
      setState(() {
        statisticsGeneral = newSettings;
      });
    });
  }

  @override
  void dispose() {
    _statisticsGeneralEvents?.cancel();

    super.dispose();
  }
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
