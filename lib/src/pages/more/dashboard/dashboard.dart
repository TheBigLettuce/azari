// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/pages/more/dashboard/dashboard_card.dart";
import "package:gallery/src/widgets/skeletons/settings.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.db});

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
    final l8n = AppLocalizations.of(context)!;

    return SettingsSkeleton(
      l8n.dashboardPage,
      state,
      appBar: AppBar(
        title: Text(l8n.dashboardPage),
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
                Wrap(
                  children: [
                    DashboardCard(
                      subtitle: l8n.cardTimeSpent,
                      title: l8n.hoursShort(
                        Duration(milliseconds: general.timeSpent).inHours,
                      ),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardScrollerUp,
                      title: general.scrolledUp.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardTagsSaved,
                      title: postTagsCount,
                    ),
                    DashboardCard(
                      subtitle: l8n.cardRefreshes,
                      title: general.refreshes.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardDownloadTime,
                      title: l8n.hoursShort(
                        Duration(milliseconds: general.timeDownload).inHours,
                      ),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardPostsViewed,
                      title: booru.viewed.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardPostsDownloaded,
                      title: booru.downloaded.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardPostsSwiped,
                      title: booru.swiped.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardBooruSwitches,
                      title: booru.booruSwitches.toString(),
                    ),
                  ],
                ),
                Wrap(
                  children: [
                    DashboardCard(
                      subtitle: l8n.cardDirectoriesViewed,
                      title: gallery.viewedDirectories.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardFilesViewed,
                      title: gallery.viewedFiles.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardFilesSwiped,
                      title: gallery.filesSwiped.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardJoinedTimes,
                      title: gallery.joined.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardSameFiltered,
                      title: gallery.sameFiltered.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardTrashed,
                      title: gallery.deleted.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardCopied,
                      title: gallery.copied.toString(),
                    ),
                    DashboardCard(
                      subtitle: l8n.cardMoved,
                      title: gallery.moved.toString(),
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
