// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/base/home.dart";
import "package:azari/src/ui/material/pages/discover/pool_page.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/home/booru_page.dart";
import "package:azari/src/ui/material/pages/search/discover/search_page.dart";
import "package:azari/src/ui/material/widgets/empty_widget.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/list_tile_list_styled.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/scaling_right_menu.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/grid_layout.dart";
import "package:azari/src/ui/material/widgets/shell/parts/shell_settings_button.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    required this.selectionController,
    required this.procPop,
  });

  final SelectionController selectionController;

  final void Function(bool) procPop;

  static bool hasServicesRequired() {
    if (!BooruCommunityAPI.supported(
      const SettingsService().current.selectedBooru,
    )) {
      return false;
    }

    return true;
  }

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with SettingsWatcherMixin {
  late final BooruCommunityAPI api;

  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.zeroSeven,
    columns: GridColumn.two,
    layoutType: GridLayoutType.grid,
  );

  final pageSaver = PageSaver.noPersist();

  late final BooruPoolsServiceHandle source;
  late final FavoritePoolServiceHandle favoritePools;

  late final SourceShellScopeElementState<BooruPool> status;

  @override
  void initState() {
    super.initState();

    favoritePools = const FavoritePoolsService().open(settings.selectedBooru);

    api = BooruCommunityAPI.fromEnum(settings.selectedBooru)!;

    source = const BooruPoolService().open(api.pools);

    status = SourceShellScopeElementState(
      source: source,
      gridSettings: gridSettings,
      selectionController: widget.selectionController,
      actions: const [],
      onEmpty: SourceOnEmptyInterface(source, (context) => "No items"),
    );
  }

  @override
  void dispose() {
    favoritePools.destroy();
    status.destroy();
    api.destroy();
    source.destroy();
    gridSettings.cancel();

    super.dispose();
  }

  void _onPressed(BooruPool pool) =>
      PoolPage.open(context, pool, favoritePools);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    final navBarEvents = NavigationButtonEvents.maybeOf(context);

    return ScalingRightMenu(
      menuContent: _DiscoverMenu(handle: favoritePools),
      child: GridPopScope(
        searchTextController: null,
        filter: null,
        rootNavigatorPop: widget.procPop,
        child: ScaffoldWithSelectionBar(
          child: ShellScope(
            settingsButton: ShellSettingsButton.onlyHeader(
              Column(
                children: [
                  _CategoryButton(handle: source),
                  _OrderButton(handle: source),
                ],
              ),
            ),
            stackInjector: status,
            appBar: RawAppBarType(
              (context, settingsButton, bottomWidget) => SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 1),
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                bottom: bottomWidget,
                leading: IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded),
                ),
                title: Center(
                  child: GestureDetector(
                    onTap: () => DiscoverSearchPage.open(
                      context,
                      favoritePools: favoritePools,
                    ),
                    child: AbsorbPointer(
                      child: Hero(
                        tag: "searchBarAnchor",
                        child: SearchBar(
                          leading: BooruLetterIcon(
                            booru: settings.selectedBooru,
                          ),
                          elevation: const WidgetStatePropertyAll(0),
                          hintText: l10n.searchHintDiscover,
                          constraints: const BoxConstraints(
                            minWidth: 360,
                            maxWidth: 460,
                            minHeight: 34,
                            maxHeight: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () {
                        ScalingRightMenu.maybeOf(context)?.open();
                      },
                      icon: const Icon(Icons.bookmarks_outlined),
                    ),
                  ),
                  if (settingsButton != null) settingsButton,
                ],
              ),
            ),
            elements: [
              ElementPriority(
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: ShellElement(
                    updateScrollPosition: source.setOffset,
                    initialScrollPosition: source.offset,
                    registerNotifiers: (child) =>
                        OnPoolPressed(onPressed: _onPressed, child: child),
                    scrollUpOn: navBarEvents != null
                        ? [(navBarEvents, null)]
                        : const [],
                    gridSettings: gridSettings,
                    state: status,
                    slivers: [
                      GridLayout<BooruPool>(
                        source: source.backingStorage,
                        progress: source.progress,
                        selection: status.selection,
                        tight: false,
                        spacing: 12,
                      ),
                      GridConfigPlaceholders(progress: source.progress),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatefulWidget {
  const _CategoryButton({
    // super.key,
    required this.handle,
  });

  final BooruPoolsServiceHandle handle;

  @override
  State<_CategoryButton> createState() => __CategoryButtonState();
}

class __CategoryButtonState extends State<_CategoryButton> {
  BooruPoolsServiceHandle get handle => widget.handle;

  late final StreamSubscription<void> watcher;

  @override
  void initState() {
    super.initState();

    watcher = widget.handle.settingsEvents.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SegmentedButtonGroup<BooruPoolCategory>(
      variant: SegmentedButtonVariant.segments,
      select: (e) {
        handle.category = e;
        handle.clearRefresh();
      },
      showSelectedIcon: false,
      allowUnselect: true,
      selected: handle.category,
      values: BooruPoolCategory.values.map(
        (e) => SegmentedButtonValue(
          e,
          e.translatedString(l10n),
          icon: switch (e) {
            BooruPoolCategory.series => Icons.link_rounded,
            BooruPoolCategory.collection => Icons.collections_rounded,
          },
        ),
      ),
      title: l10n.categoryLabel,
    );
  }
}

class _OrderButton extends StatefulWidget {
  const _OrderButton({
    // super.key,
    required this.handle,
  });

  final BooruPoolsServiceHandle handle;

  @override
  State<_OrderButton> createState() => _OrderButtonState();
}

class _OrderButtonState extends State<_OrderButton> {
  BooruPoolsServiceHandle get handle => widget.handle;

  late final StreamSubscription<void> watcher;

  @override
  void initState() {
    super.initState();

    watcher = widget.handle.settingsEvents.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SegmentedButtonGroup<BooruPoolsOrder>(
      select: (e) {
        if (e != null) {
          handle.order = e;
          handle.clearRefresh();
        }
      },
      selected: handle.order,
      reorder: false,
      values: BooruPoolsOrder.values.map(
        (e) =>
            SegmentedButtonValue(e, e.translatedString(l10n), icon: e.icon()),
      ),
      title: l10n.orderLabel,
      variant: SegmentedButtonVariant.chip,
    );
  }
}

class _DiscoverMenu extends StatefulWidget {
  const _DiscoverMenu({
    // super.key,
    required this.handle,
  });

  final FavoritePoolServiceHandle handle;

  @override
  State<_DiscoverMenu> createState() => __DiscoverMenuState();
}

class __DiscoverMenuState extends State<_DiscoverMenu> {
  late final StreamSubscription<void> _poolEvents;

  List<BooruPool> pools = const [];

  @override
  void initState() {
    super.initState();

    pools = widget.handle.all;

    _poolEvents = widget.handle.events.listen((_) {
      setState(() {
        pools = widget.handle.all;
      });
    });
  }

  @override
  void dispose() {
    _poolEvents.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return pools.isEmpty
        ? EmptyWidgetBackground(subtitle: l10n.noBookmarks)
        : ListTileListStyled(
            itemCount: pools.length,
            itemBuilder: (context, index) {
              final pool = pools[index];

              return ListTile(
                onTap: () => PoolPage.open(context, pool, widget.handle),
                trailing: IconButton(
                  onPressed: () => widget.handle.remove(pool),
                  icon: const Icon(Icons.bookmark_remove_rounded),
                ),
                leading: SizedBox.square(
                  dimension: 48,
                  child: GridCellImage(
                    blur: false,
                    imageAlign: Alignment.center,
                    thumbnail: CachedNetworkImageProvider(pool.thumbUrl),
                  ),
                ),
                title: Text(
                  pool.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  pool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
  }
}

class _PoolButton extends StatefulWidget {
  const _PoolButton({
    // super.key,
    required this.source,
  });

  final BooruPoolsServiceHandle source;

  @override
  State<_PoolButton> createState() => _PoolButtonState();
}

class _PoolButtonState extends State<_PoolButton> {
  late final StreamSubscription<void> _events;

  @override
  void initState() {
    super.initState();

    _events = widget.source.settingsEvents.listen((e) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () {
        switch (widget.source.order) {
          case BooruPoolsOrder.latest:
            widget.source.order = BooruPoolsOrder.creationTime;
          case BooruPoolsOrder.creationTime:
            widget.source.order = BooruPoolsOrder.postCount;
          case BooruPoolsOrder.postCount:
            widget.source.order = BooruPoolsOrder.latest;
          case BooruPoolsOrder.name:
        }

        widget.source.clearRefresh();
      },
      icon: Icon(switch (widget.source.order) {
        BooruPoolsOrder.name => Icons.sort_by_alpha_rounded,
        BooruPoolsOrder.latest => Icons.new_releases_rounded,
        BooruPoolsOrder.creationTime => Icons.access_time_rounded,
        BooruPoolsOrder.postCount => Icons.onetwothree_rounded,
      }),
    );
  }
}

typedef OnPoolPressedFunc = void Function(BooruPool pool);

class OnPoolPressed extends InheritedWidget {
  const OnPoolPressed({
    super.key,
    required this.onPressed,
    required super.child,
  });

  final OnPoolPressedFunc onPressed;

  static OnPoolPressedFunc of(BuildContext context) => maybeOf(context)!;

  static OnPoolPressedFunc? maybeOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<OnPoolPressed>();

    return widget?.onPressed;
  }

  @override
  bool updateShouldNotify(OnPoolPressed oldWidget) =>
      oldWidget.onPressed != onPressed;
}
