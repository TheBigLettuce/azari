// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/pages/home.dart";
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
    final l10n = AppLocalizations.of(context)!;

    return SettingsSkeleton(
      l10n.dashboardPage,
      state,
      appBar: AppBar(
        title: Text(l10n.dashboardPage),
        leading: IconButton(
          onPressed: () {
            MoreSubPage.selectOf(context, MoreSubPage.more);
          },
          icon: const Icon(Icons.arrow_back),
        ),
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
                        Duration(milliseconds: general.timeDownload).inHours,
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
          ),
        ),
      ),
    );
  }
}
