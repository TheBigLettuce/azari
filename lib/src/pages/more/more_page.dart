// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/app_info.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/download_manager/download_manager.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/home.dart";
import "package:azari/src/pages/more/dashboard/dashboard.dart";
import "package:azari/src/pages/more/downloads/downloads.dart";
import "package:azari/src/pages/more/settings/settings_widget.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    required this.db,
    required this.popScope,
  });

  final DbConn db;
  final void Function(bool) popScope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (MoreSubPage.of(context)) {
      MoreSubPage.more => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: popScope,
          child: AnnotatedRegion(
            value: SystemUiOverlayStyle(
              statusBarIconBrightness: theme.brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarColor: theme.colorScheme.surface.withOpacity(0),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 12,
                    top: 12 + 40 + MediaQuery.viewPaddingOf(context).top,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            icon: const Icon(Icons.download_outlined),
                            onPressed: () {
                              final g = GlueProvider.generateOf(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) {
                                    return Downloads(
                                      generateGlue: g,
                                      downloadManager:
                                          DownloadManager.of(context),
                                      db: db,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const Padding(padding: EdgeInsets.only(left: 8)),
                          IconButton.filled(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute<void>(
                                  builder: (context) {
                                    return const SettingsWidget();
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: 0.4363323,
                        child: Icon(
                          const IconData(0x963F),
                          size: 78,
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          applyTextScaling: true,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 12)),
                      Text(
                        AppInfo().version,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      MoreSubPage.dashboard => GridPopScope(
          searchTextController: null,
          filter: null,
          rootNavigatorPop: popScope,
          child: Dashboard(
            db: db.localTags,
            popScope: popScope,
          ),
        ),
    };
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
