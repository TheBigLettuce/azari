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
      "Dashboard",
      state,
      appBar: AppBar(
        title: Text("Dashboard"),
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
                const _Label(text: "Booru"),
                Wrap(
                  children: [
                    DashboardCard(
                      subtitle: "Time spent",
                      title: "${general.timeSpent.milliseconds.inHours} hrs",
                    ),
                    DashboardCard(
                      subtitle: "Scrolled up",
                      title: general.scrolledUp.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Tags saved",
                      title: postTagsCount,
                    ),
                    DashboardCard(
                      subtitle: "Refreshes",
                      title: general.refreshes.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Download time",
                      title: "${general.timeDownload.milliseconds.inHours} hrs",
                    ),
                    DashboardCard(
                      subtitle: "Posts viewed",
                      title: booru.viewed.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Posts downloaded",
                      title: booru.downloaded.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Posts swiped",
                      title: booru.swiped.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Booru switches",
                      title: booru.booruSwitches.toString(),
                    ),
                  ],
                ),
                const _Label(text: "Gallery"),
                Wrap(
                  children: [
                    DashboardCard(
                      subtitle: "Directories viewed",
                      title: gallery.viewedDirectories.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Files viewed",
                      title: gallery.viewedFiles.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Files swiped",
                      title: gallery.filesSwiped.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Joined times",
                      title: gallery.joined.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Same filtered",
                      title: gallery.sameFiltered.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Trashed",
                      title: gallery.deleted.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Copied",
                      title: gallery.copied.toString(),
                    ),
                    DashboardCard(
                      subtitle: "Moved",
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
  const _Label({super.key, required this.text});

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
