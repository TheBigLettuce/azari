// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/more/dashboard/dashboard_card.dart";
import "package:azari/src/widgets/skeletons/settings.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    required this.db,
    required this.popScope,
  });

  final void Function(bool) popScope;
  final LocalTagsService db;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final gallery = StatisticsGalleryService.db().current;
  final booru = StatisticsBooruService.db().current;
  final general = StatisticsGeneralService.db().current;
  late final postTagsCount = widget.db.count.toString();

  final state = SkeletonState();

  @override
  void dispose() {
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withOpacity(0.8);

    final l10n = AppLocalizations.of(context)!;

    final (time, stream) = TimeSpentNotifier.streamOf(context);

    final timeNow = DateTime.now();
    final emoji = timeNow.hour > 20 || timeNow.hour <= 6 ? "🌙" : "☀️";

    return SettingsSkeleton(
      l10n.dashboardPage,
      state,
      appBar: AppBar(
        title: Text(l10n.dashboardPage),
        leading: IconButton(
          onPressed: () {
            widget.popScope(false);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom +
                MediaQuery.paddingOf(context).bottom,
          ),
          child: Center(
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 8)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${l10n.date(timeNow)} $emoji",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 40)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Center(
                        child: TimeSpentWidget(
                          stream: stream,
                          initalDuration: time,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              StatisticsDailyService.db()
                                  .current
                                  .swipedBoth
                                  .toString(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: color,
                              ),
                            ),
                            Text(
                              l10n.cardPicturesSeenToday,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: color.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(padding: EdgeInsets.only(top: 24)),
                Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: [
                    Wrap(
                      children: [
                        DashboardCard(
                          subtitle: l10n.cardTimeSpent,
                          title: l10n.hoursShort(
                            Duration(milliseconds: general.timeSpent).inHours,
                          ),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardScrollerUp,
                          title: general.scrolledUp.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardTagsSaved,
                          title: postTagsCount,
                        ),
                        DashboardCard(
                          subtitle: l10n.cardRefreshes,
                          title: general.refreshes.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardDownloadTime,
                          title: l10n.hoursShort(
                            Duration(milliseconds: general.timeDownload)
                                .inHours,
                          ),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardPostsViewed,
                          title: booru.viewed.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardPostsDownloaded,
                          title: booru.downloaded.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardPostsSwiped,
                          title: booru.swiped.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardBooruSwitches,
                          title: booru.booruSwitches.toString(),
                        ),
                      ],
                    ),
                    Wrap(
                      children: [
                        DashboardCard(
                          subtitle: l10n.cardDirectoriesViewed,
                          title: gallery.viewedDirectories.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardFilesViewed,
                          title: gallery.viewedFiles.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardFilesSwiped,
                          title: gallery.filesSwiped.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardJoinedTimes,
                          title: gallery.joined.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardSameFiltered,
                          title: gallery.sameFiltered.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardTrashed,
                          title: gallery.deleted.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardCopied,
                          title: gallery.copied.toString(),
                        ),
                        DashboardCard(
                          subtitle: l10n.cardMoved,
                          title: gallery.moved.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final color = theme.colorScheme.onSurface.withOpacity(0.8);

    final l10n = AppLocalizations.of(context)!;

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
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
