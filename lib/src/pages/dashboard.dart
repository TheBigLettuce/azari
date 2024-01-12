// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_booru.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_gallery.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_general.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../db/tags/post_tags.dart';
import '../widgets/dashboard_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final gallery = StatisticsGallery.current;
  final booru = StatisticsBooru.current;
  final general = StatisticsGeneral.current;
  final postTagsCount = PostTags.g.savedTagsCount().toString();

  final state = SkeletonState();

  @override
  void dispose() {
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonSettings(
      AppLocalizations.of(context)!.dashboardPage,
      state,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboardPage),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                _Label(text: AppLocalizations.of(context)!.booruLabel),
                Wrap(
                  children: [
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardTimeSpent,
                      title: AppLocalizations.of(context)!
                          .hoursShort(general.timeSpent.milliseconds.inHours),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardScrollerUp,
                      title: general.scrolledUp.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardTagsSaved,
                      title: postTagsCount,
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardRefreshes,
                      title: general.refreshes.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardDownloadTime,
                      title: AppLocalizations.of(context)!.hoursShort(
                          general.timeDownload.milliseconds.inHours),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardPostsViewed,
                      title: booru.viewed.toString(),
                    ),
                    DashboardCard(
                      subtitle:
                          AppLocalizations.of(context)!.cardPostsDownloaded,
                      title: booru.downloaded.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardPostsSwiped,
                      title: booru.swiped.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardBooruSwitches,
                      title: booru.booruSwitches.toString(),
                    ),
                  ],
                ),
                _Label(text: AppLocalizations.of(context)!.galleryLabel),
                Wrap(
                  children: [
                    DashboardCard(
                      subtitle:
                          AppLocalizations.of(context)!.cardDirectoriesViewed,
                      title: gallery.viewedDirectories.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardFilesViewed,
                      title: gallery.viewedFiles.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardFilesSwiped,
                      title: gallery.filesSwiped.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardJoinedTimes,
                      title: gallery.joined.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardSameFiltered,
                      title: gallery.sameFiltered.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardTrashed,
                      title: gallery.deleted.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardCopied,
                      title: gallery.copied.toString(),
                    ),
                    DashboardCard(
                      subtitle: AppLocalizations.of(context)!.cardMoved,
                      title: gallery.moved.toString(),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 2,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }
}
