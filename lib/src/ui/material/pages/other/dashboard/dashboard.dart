// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/typedefs.dart";
import "package:flutter/material.dart";

class TimeSpentWidget extends StatefulWidget {
  const TimeSpentWidget({
    super.key,
    required this.stream,
    required this.initalDuration,
  });

  final Stream<Duration> stream;
  final Duration initalDuration;

  @override
  State<TimeSpentWidget> createState() => _TimeSpentWidgetState();
}

class _TimeSpentWidgetState extends State<TimeSpentWidget> {
  late Duration duration = widget.initalDuration;
  late final StreamSubscription<Duration> watcher;

  @override
  void initState() {
    super.initState();

    watcher = widget.stream.listen((event) {
      setState(() {
        duration = event;
      });
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  String timeStr(AppLocalizations l10n) {
    var microseconds = duration.inMicroseconds;
    var sign = "";
    final negative = microseconds < 0;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);

    if (negative) {
      hours = 0 - hours;
      microseconds = 0 - microseconds;
      sign = "-";
    }

    final minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

    final minutesPadding = minutes < 10 ? "0" : "";

    final seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

    final secondsPadding = seconds < 10 ? "0" : "";

    return "${hours != 0 ? "$sign${l10n.hoursShort(hours)} " : ""}"
        "${minutes != 0 ? "$minutesPadding${l10n.minutesShort(minutes)} " : ""}"
        "$secondsPadding${l10n.secondsShort(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.8);

    final l10n = context.l10n();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeStr(l10n),
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
          ),
        ),
        Text(
          l10n.cardTimeSpentToday,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.statisticsDaily,
    required this.statisticsGeneral,
  });

  final StatisticsDailyService statisticsDaily;
  final StatisticsGeneralService statisticsGeneral;

  static Future<void> open(
    BuildContext context, {
    required StatisticsDailyService statisticsDaily,
    required StatisticsGeneralService statisticsGeneral,
  }) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) {
            return DashboardPage(
              statisticsDaily: statisticsDaily,
              statisticsGeneral: statisticsGeneral,
            );
          },
        ),
      );

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(l10n.dashboardPage),
          ),
          _GeneralStatistics(statisticsGeneral: widget.statisticsGeneral),
          _DailyStatistics(statisticsDaily: widget.statisticsDaily),
        ],
      ),
    );
  }
}

class _DailyStatistics extends StatefulWidget {
  const _DailyStatistics({
    // super.key,
    required this.statisticsDaily,
  });

  final StatisticsDailyService statisticsDaily;

  @override
  State<_DailyStatistics> createState() => __DailyStatisticsState();
}

class __DailyStatisticsState extends State<_DailyStatistics>
    with StatisticsDailyWatcherMixin {
  @override
  StatisticsDailyService get statisticsDailyService => widget.statisticsDaily;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SliverGrid.count(
      crossAxisCount: 3,
      children: [
        // _DashboardCard(
        //   value: currentData.refreshes.toString(),
        //   title: "Refreshes",
        // ),
        _DashboardCard(
          value: l10n.dateSimple(statisticsDaily.date),
          title: "Date",
        ),
        _DashboardCard(
          value: l10n.minutesShort(
            Duration(milliseconds: statisticsDaily.durationMillis).inMinutes,
          ),
          title: "Time spent",
        ),
        _DashboardCard(
          title: "Swiped",
          value: statisticsDaily.swipedBoth.toString(),
        ),
      ],
    );
  }
}

class _GeneralStatistics extends StatefulWidget {
  const _GeneralStatistics({
    // super.key,
    required this.statisticsGeneral,
  });

  final StatisticsGeneralService statisticsGeneral;

  @override
  State<_GeneralStatistics> createState() => __GeneralStatisticsState();
}

class __GeneralStatisticsState extends State<_GeneralStatistics>
    with StatisticsGeneralWatcherMixin {
  @override
  StatisticsGeneralService get statisticsGeneralService =>
      widget.statisticsGeneral;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SliverGrid.count(
      crossAxisCount: 3,
      children: [
        _DashboardCard(
          value: statisticsGeneral.refreshes.toString(),
          title: "Refreshes",
        ),
        _DashboardCard(
          value: statisticsGeneral.scrolledUp.toString(),
          title: "Scrolled up",
        ),
        _DashboardCard(
          value: l10n.minutesShort(
            Duration(milliseconds: statisticsGeneral.timeDownload).inMinutes,
          ),
          title: "Time downloaded",
        ),
        _DashboardCard(
          title: "Time spent",
          value: l10n.minutesShort(
            Duration(milliseconds: statisticsGeneral.timeSpent).inMinutes,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    // super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
