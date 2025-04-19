// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/booru_page_mixin.dart";
import "package:azari/src/logic/resource_source/resource_source.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/cupertino.dart";

class AppCupertino extends StatefulWidget {
  const AppCupertino({
    super.key,
  });

  @override
  State<AppCupertino> createState() => _AppCupertinoState();
}

class _AppCupertinoState extends State<AppCupertino> {
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final PagingStateRegistry pagingRegistry;
  final selectionEvents = SelectionActions();

  @override
  void initState() {
    super.initState();

    pagingRegistry = PagingStateRegistry();
  }

  @override
  void dispose() {
    pagingRegistry.recycle();
    selectionEvents.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return selectionEvents.inject(
      CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
              label: const SettingsService().current.selectedBooru.string,
              icon: const Icon(CupertinoIcons.home),
            ),
            BottomNavigationBarItem(
              label: l10n.discoverPage,
              icon: const Icon(CupertinoIcons.search_circle_fill),
            ),
            BottomNavigationBarItem(
              label: l10n.galleryLabel,
              icon: const Icon(CupertinoIcons.photo),
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) => CupertinoPageScaffold(
              child: switch (index) {
                0 => BooruPage(
                    pagingRegistry: pagingRegistry,
                    selectionController: SelectionActions.controllerOf(context),
                  ),
                int() => const Placeholder(),
              },
            ),
          );
        },
      ),
    );
  }
}

class BooruPage extends StatefulWidget {
  const BooruPage({
    super.key,
    required this.pagingRegistry,
    required this.selectionController,
  });

  final PagingStateRegistry pagingRegistry;
  final SelectionController selectionController;

  @override
  State<BooruPage> createState() => _BooruPageState();
}

class _BooruPageState extends State<BooruPage>
    with SettingsWatcherMixin, BooruPageMixin {
  @override
  PagingStateRegistry get pagingRegistry => widget.pagingRegistry;

  @override
  SelectionController get selectionController => widget.selectionController;

  @override
  void openSecondaryBooruPage(GridBookmark bookmark) {}

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemCount: source.count,
      itemBuilder: (context, index) {
        final data = source.forIdxUnsafe(index);

        return GridCell(
          title: null,
          uniqueKey: data.uniqueKey(),
          thumbnail: data.thumbnail(),
        );
      },
    );
  }
}
