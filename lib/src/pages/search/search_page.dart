// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/pages/search/booru/booru_search_page.dart";
import "package:azari/src/pages/search/gallery/gallery_search_page.dart";
import "package:flutter/material.dart";

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final db = DatabaseConnectionNotifier.of(context);

    return Scaffold(
      appBar: TabBar(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 12,
          right: 12,
        ),
        splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: const BoxDecoration(),
        labelStyle: theme.textTheme.titleMedium
            ?.copyWith(color: theme.colorScheme.primary),
        unselectedLabelStyle: theme.textTheme.titleSmall,
        dividerHeight: 0,
        tabs: const [
          Tab(
            text: "Booru",
            height: 32,
          ),
          Tab(
            text: "Gallery",
            height: 32,
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          BooruSearchPage(db: db),
          GallerySearchPage(
            db: db,
            l10n: l10n,
          ),
        ],
      ),
    );
  }
}
