// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";
import "dart:math" as math;

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/booru.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_directories.dart";
import "package:gallery/src/interfaces/gallery/gallery_api_files.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/pages/booru/booru_page.dart";
import "package:gallery/src/pages/booru/booru_restored_page.dart";
import "package:gallery/src/pages/gallery/callback_description.dart";
import "package:gallery/src/pages/gallery/callback_description_nested.dart";
import "package:gallery/src/pages/gallery/directories.dart";
import "package:gallery/src/pages/gallery/files_filters.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/plugs/gallery_management_api.dart";
import "package:gallery/src/plugs/notifications.dart";
import "package:gallery/src/plugs/platform_functions.dart";
import "package:gallery/src/widgets/copy_move_preview.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_masonry_layout.dart";
import "package:gallery/src/widgets/grid_frame/layouts/grid_quilted.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:gallery/src/widgets/make_tags.dart";
import "package:gallery/src/widgets/notifiers/glue_provider.dart";
import "package:gallery/src/widgets/notifiers/pause_video.dart";
import "package:gallery/src/widgets/search_bar/search_filter_grid.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

part "files_actions_mixin.dart";

bool _isSavingTags = false;

class GalleryFiles extends StatefulWidget {
  const GalleryFiles({
    super.key,
    required this.api,
    this.callback,
    required this.dirName,
    required this.bucketId,
    required this.secure,
    required this.generateGlue,
    required this.db,
    required this.tagManager,
  });

  final String dirName;
  final String bucketId;
  final GalleryAPIFiles api;
  final CallbackDescriptionNested? callback;
  final SelectionGlue Function([Set<GluePreferences>])? generateGlue;
  final bool secure;

  final DbConn db;
  final TagManager tagManager;

  @override
  State<GalleryFiles> createState() => _GalleryFilesState();
}

class _GalleryFilesState extends State<GalleryFiles> with FilesActionsMixin {
  FavoriteFileService get favoriteFiles => widget.db.favoriteFiles;
  LocalTagsService get localTags => widget.db.localTags;
  WatchableGridSettingsData get gridSettings => widget.db.gridSettings.files;

  final GlobalKey<BarIconState> _favoriteButtonKey = GlobalKey();
  final GlobalKey<BarIconState> _duplicateButtonKey = GlobalKey();

  GalleryAPIFiles get api => widget.api;

  AppLifecycleListener? _listener;
  StreamSubscription<void>? _subscription;

  final miscSettings = MiscSettingsService.db().current;

  late final postTags = PostTags(localTags, widget.db.localTagDictionary);

  static const _log = LogTarget.gallery;

  final plug = chooseGalleryPlug();

  late final StreamSubscription<SettingsData?> settingsWatcher;

  late final ChainedFilterResourceSource<int, GalleryFile> filter;

  late final GridSkeletonState<GalleryFile> state = GridSkeletonState();

  final searchTextController = TextEditingController();
  final searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    filter = ChainedFilterResourceSource(
      api.source,
      ListStorage(),
      onCompletelyEmpty: () {
        Navigator.pop(context);
      },
      prefilter: () {
        if (filter.filteringMode == FilteringMode.favorite) {
          _favoriteButtonKey.currentState?.toggle(true);
          _duplicateButtonKey.currentState?.toggle(false);
        } else if (filter.filteringMode == FilteringMode.duplicate) {
          _duplicateButtonKey.currentState?.toggle(true);
          _favoriteButtonKey.currentState?.toggle(false);
        } else {
          _duplicateButtonKey.currentState?.toggle(false);
          _favoriteButtonKey.currentState?.toggle(false);
          beforeButtons = null;
        }

        if (filter.filteringMode == FilteringMode.same) {
          StatisticsGalleryService.db().current.add(sameFiltered: 1).save();
        }
      },
      filter: (cells, filteringMode, sortingMode, end, [data]) {
        return switch (filteringMode) {
          FilteringMode.favorite => FileFilters.favorite(cells, favoriteFiles),
          FilteringMode.untagged => FileFilters.untagged(cells, localTags),
          FilteringMode.tag =>
            FileFilters.tag(cells, searchTextController.text, postTags),
          FilteringMode.tagReversed =>
            FileFilters.tagReversed(cells, searchTextController.text, postTags),
          FilteringMode.video => FileFilters.video(cells),
          FilteringMode.gif => FileFilters.gif(cells),
          FilteringMode.duplicate => FileFilters.duplicate(cells),
          FilteringMode.original => FileFilters.original(cells, localTags),
          FilteringMode.same => FileFilters.same(
              context,
              cells,
              data,
              performSearch: () =>
                  api.source.clearRefreshSorting(filter.sortingMode, true),
              end: end,
              source: api.source,
            ),
          FilteringMode() => (
              searchTextController.text.isEmpty
                  ? cells
                  : cells
                      .where((e) => e.name.contains(searchTextController.text)),
              data
            ),
        };
      },
      allowedFilteringModes: {
        FilteringMode.noFilter,
        if (api.type != GalleryFilesPageType.favorites) FilteringMode.favorite,
        FilteringMode.original,
        FilteringMode.duplicate,
        FilteringMode.same,
        FilteringMode.tag,
        FilteringMode.tagReversed,
        FilteringMode.untagged,
        FilteringMode.gif,
        FilteringMode.video,
      },
      allowedSortingModes: const {
        SortingMode.none,
        SortingMode.size,
      },
      initialFilteringMode: FilteringMode.noFilter,
      initialSortingMode: SortingMode.none,
    );

    settingsWatcher = state.settings.s.watch((s) {
      state.settings = s!;

      setState(() {});
    });

    if (widget.secure) {
      _listener = AppLifecycleListener(
        onHide: () {
          _subscription?.cancel();
          _subscription = Stream<void>.periodic(const Duration(seconds: 10))
              .listen((event) {
            filter.backingStorage.clear();

            Navigator.of(context).pop();

            _subscription?.cancel();

            return;
          });
        },
        onShow: () {
          _subscription?.cancel();
          _subscription = null;
        },
      );

      const AndroidApiFunctions().hideRecents(true);
    }

    api.source.clearRefreshSorting(filter.sortingMode, true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _listener?.dispose();
    settingsWatcher.cancel();

    searchTextController.dispose();
    searchFocus.dispose();
    filter.destroy();

    api.close();
    state.dispose();

    const AndroidApiFunctions().hideRecents(false);

    super.dispose();
  }

  void _onBooruTagPressed(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? overrideSafeMode,
  ) {
    if (overrideSafeMode != null) {
      PauseVideoNotifier.maybePauseOf(context, true);

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) {
            return BooruRestoredPage(
              booru: booru,
              tags: tag,
              wrapScaffold: true,
              saveSelectedPage: (e) {},
              overrideSafeMode: overrideSafeMode,
              db: widget.db,
            );
          },
        ),
      ).then((value) {
        PauseVideoNotifier.maybePauseOf(context, false);
      });

      return;
    }

    Navigator.pop(context);

    searchTextController.text = tag;
    filter.filteringMode = FilteringMode.tag;
  }

  FilteringMode? beforeButtons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GridConfiguration(
      watch: gridSettings.watch,
      child: WrapGridPage(
        addScaffold: widget.callback != null,
        provided: widget.generateGlue,
        child: GridPopScope(
          searchTextController: searchTextController,
          filter: filter,
          searchFocus: searchFocus,
          child: Builder(
            builder: (context) => GridFrame<GalleryFile>(
              key: state.gridKey,
              slivers: [
                if (!api.type.isFavorites())
                  Builder(
                    builder: (context) {
                      return IconBarGridHeader(
                        icons: [
                          BarIcon(
                            icon: Icons.select_all_rounded,
                            onPressed: () {
                              final gridExtras =
                                  GridExtrasNotifier.of<GalleryFile>(context);

                              if (gridExtras.selection.count ==
                                  gridExtras.functionality.source.count) {
                                gridExtras.selection.reset(true);
                              } else {
                                gridExtras.selection.selectAll(context);
                              }

                              return null;
                            },
                          ),
                          BarIcon(
                            key: _duplicateButtonKey,
                            icon: FilteringMode.duplicate.icon,
                            onPressed: () {
                              if (filter.filteringMode ==
                                  FilteringMode.duplicate) {
                                filter.filteringMode = beforeButtons ==
                                        FilteringMode.duplicate
                                    ? FilteringMode.noFilter
                                    : (beforeButtons ?? FilteringMode.noFilter);
                                return false;
                              } else {
                                beforeButtons = filter.filteringMode;
                                filter.filteringMode = FilteringMode.duplicate;
                                return true;
                              }
                            },
                          ),
                          BarIcon(
                            key: _favoriteButtonKey,
                            icon: FilteringMode.favorite.icon,
                            onPressed: () {
                              if (filter.filteringMode ==
                                  FilteringMode.favorite) {
                                filter.filteringMode = beforeButtons ==
                                        FilteringMode.favorite
                                    ? FilteringMode.noFilter
                                    : beforeButtons ?? FilteringMode.noFilter;
                                return false;
                              } else {
                                beforeButtons = filter.filteringMode;
                                filter.filteringMode = FilteringMode.favorite;
                                return true;
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                CurrentGridSettingsLayout<GalleryFile>(
                  source: filter.backingStorage,
                  progress: filter.progress,
                  gridSeed: state.gridSeed,
                ),
                GridFooter<StatisticsGalleryData>(
                  storage: filter.backingStorage,
                  name: widget.dirName,
                  statistics: (
                    (value) => [
                          StatisticsCard(
                            subtitle: value.viewedFiles.toString(),
                            title: l10n.cardFilesViewed,
                          ),
                          StatisticsCard(
                            subtitle: value.filesSwiped.toString(),
                            title: l10n.cardFilesSwiped,
                          ),
                          StatisticsCard(
                            subtitle: value.moved.toString(),
                            title: l10n.cardMoved,
                          ),
                          StatisticsCard(
                            subtitle: value.copied.toString(),
                            title: l10n.cardCopied,
                          ),
                        ],
                    widget.db.statisticsGallery.watch,
                  ),
                ),
              ],
              functionality: GridFunctionality(
                settingsButton: GridSettingsButton.fromWatchable(gridSettings),
                registerNotifiers: (child) {
                  return FilesDataNotifier(
                    actions: this,
                    api: widget.api,
                    nestedCallback: widget.callback,
                    child: OnBooruTagPressed(
                      onPressed: _onBooruTagPressed,
                      child: child,
                    ),
                  );
                },
                backButton: CallbackGridBackButton(
                  onPressed: () {
                    if (filter.filteringMode != FilteringMode.noFilter) {
                      filter.filteringMode = FilteringMode.noFilter;
                      return;
                    }
                    Navigator.pop(context);
                  },
                ),
                selectionGlue: GlueProvider.generateOf(context)(),
                source: filter,
                search: OverrideGridSearchWidget(
                  SearchAndFocus(
                    FilteringSearchWidget(
                      hint: widget.dirName,
                      filter: filter,
                      textController: searchTextController,
                      localTagDictionary: widget.db.localTagDictionary,
                      focusNode: searchFocus,
                    ),
                    searchFocus,
                  ),
                ),
              ),
              description: GridDescription(
                overrideEmptyWidgetNotice:
                    api.type.isFavorites() ? l10n.someFilesShownNotice : null,
                actions: widget.callback != null
                    ? const []
                    : api.type.isTrash()
                        ? [
                            restoreFromTrash(),
                          ]
                        : [
                            if (api.type.isFavorites())
                              setFavoritesThumbnailAction(
                                widget.db.miscSettings,
                              ),
                            if (miscSettings.filesExtendedActions) ...[
                              saveTagsAction(plug, postTags, localTags),
                              addTag(
                                context,
                                () => api.source.clearRefreshSorting(
                                  filter.sortingMode,
                                  true,
                                ),
                                localTags,
                              ),
                            ],
                            addToFavoritesAction(null, favoriteFiles),
                            deleteAction(),
                            copyAction(
                              widget.tagManager,
                              favoriteFiles,
                              localTags,
                              api.parent,
                            ),
                            moveAction(
                              widget.tagManager,
                              favoriteFiles,
                              localTags,
                              api.parent,
                            ),
                          ],
                menuButtonItems: [
                  if (widget.callback == null && api.type.isTrash())
                    IconButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          DialogRoute<void>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(l10n.emptyTrashTitle),
                                content: Text(
                                  l10n.thisIsPermanent,
                                  style: TextStyle(
                                    color: Colors.red.harmonizeWith(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      GalleryManagementApi.current()
                                          .emptyTrash();
                                      Navigator.pop(context);
                                    },
                                    child: Text(l10n.yes),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(l10n.no),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_outlined),
                    ),
                  if (widget.callback != null)
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () {
                          if (filter.progress.inRefreshing) {
                            return;
                          }

                          final upTo = filter.backingStorage.count;

                          try {
                            final n = math.Random.secure().nextInt(upTo);

                            final gridState = state.gridKey.currentState;
                            if (gridState != null) {
                              final cell = gridState.source.forIdxUnsafe(n);
                              cell.onPress(
                                context,
                                gridState.widget.functionality,
                                cell,
                                n,
                              );
                            }
                          } catch (e, trace) {
                            _log.logDefaultImportant(
                              "getting random number".errorMessage(e),
                              trace,
                            );

                            return;
                          }

                          if (widget.callback!.returnBack) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.casino_outlined),
                      ),
                    ),
                ],
                inlineMenuButtonItems: true,
                bottomWidget: widget.callback != null
                    ? CopyMovePreview.hintWidget(
                        context,
                        l10n.pickFileNotice,
                        widget.callback!.icon,
                      )
                    : null,
                keybindsDescription: widget.dirName,
                gridSeed: state.gridSeed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BarIcon extends StatefulWidget {
  const BarIcon({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final bool? Function() onPressed;

  @override
  State<BarIcon> createState() => BarIconState();
}

class BarIconState extends State<BarIcon> {
  bool _toggled = false;

  void toggle(bool v) => setState(() {
        _toggled = v;
      });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      isSelected: _toggled,
      onPressed: () {
        final ret = widget.onPressed();
        if (ret != null) {
          setState(() {
            _toggled = ret;
          });
        }
      },
      icon: Icon(widget.icon),
    );
  }
}

class IconBarGridHeader extends StatelessWidget {
  const IconBarGridHeader({
    super.key,
    required this.icons,
  });

  final List<BarIcon> icons;

  @override
  Widget build(BuildContext context) {
    final gestureInsets = MediaQuery.systemGestureInsetsOf(context);

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: 8 + gestureInsets.right * 0.5,
        vertical: 4,
      ),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: icons,
          ),
        ),
      ),
    );
  }
}

class CurrentGridSettingsLayout<T extends CellBase> extends StatelessWidget {
  const CurrentGridSettingsLayout({
    super.key,
    required this.source,
    this.hideThumbnails = false,
    required this.gridSeed,
    this.buildEmpty,
    required this.progress,
    this.unselectOnUpdate = true,
  });

  final SourceStorage<int, T> source;
  final bool hideThumbnails;
  final int gridSeed;
  final Widget Function(Object?)? buildEmpty;
  final RefreshingProgress progress;

  final bool unselectOnUpdate;

  @override
  Widget build(BuildContext context) {
    final config = GridConfiguration.of(context);

    return switch (config.layoutType) {
      GridLayoutType.grid => GridLayout<T>(
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          unselectOnUpdate: unselectOnUpdate,
        ),
      GridLayoutType.list => ListLayout<T>(
          hideThumbnails: hideThumbnails,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          unselectOnUpdate: unselectOnUpdate,
        ),
      GridLayoutType.gridQuilted => GridQuiltedLayout<T>(
          randomNumber: gridSeed,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          unselectOnUpdate: unselectOnUpdate,
        ),
      GridLayoutType.gridMasonry => GridMasonryLayout(
          randomNumber: gridSeed,
          source: source,
          progress: progress,
          buildEmpty: buildEmpty,
          unselectOnUpdate: unselectOnUpdate,
        ),
    };
  }
}

class FilesDataNotifier extends InheritedWidget {
  const FilesDataNotifier({
    super.key,
    required this.api,
    required this.actions,
    required this.nestedCallback,
    required super.child,
  });

  final GalleryAPIFiles api;
  final CallbackDescriptionNested? nestedCallback;
  final FilesActionsMixin actions;

  static (
    GalleryAPIFiles,
    CallbackDescriptionNested?,
    FilesActionsMixin,
  ) of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<FilesDataNotifier>();

    return (
      widget!.api,
      widget.nestedCallback,
      widget.actions,
    );
  }

  @override
  bool updateShouldNotify(FilesDataNotifier oldWidget) =>
      api != oldWidget.api ||
      nestedCallback != oldWidget.nestedCallback ||
      actions != oldWidget.actions;
}

class GridFooter<T> extends StatefulWidget {
  const GridFooter({
    super.key,
    required this.storage,
    this.name,
    this.statistics,
  });

  final ReadOnlyStorage<dynamic, dynamic> storage;
  final String? name;

  final (List<Widget> Function(T), WatchFire<T>)? statistics;

  @override
  State<GridFooter<T>> createState() => _GridFooterState();
}

class _GridFooterState<T> extends State<GridFooter<T>> {
  late final StreamSubscription<int> watcher;

  @override
  void initState() {
    super.initState();

    watcher = widget.storage.watch((_) => setState(() {}));
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (widget.storage.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    if (widget.name != null)
                      TextSpan(
                        text: "${widget.name}\n",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    TextSpan(
                      text:
                          "${widget.storage.count} ${widget.storage.count == 1 ? l10n.elementSingular : l10n.elementPlural}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.statistics != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "~",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              if (widget.statistics != null)
                _StatisticsPanel<T>(statistics: widget.statistics!),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsPanel<T> extends StatefulWidget {
  const _StatisticsPanel({
    super.key,
    required this.statistics,
  });

  final (List<Widget> Function(T), WatchFire<T>) statistics;

  @override
  State<_StatisticsPanel<T>> createState() => __StatisticsPanelState();
}

class __StatisticsPanelState<T> extends State<_StatisticsPanel<T>> {
  late final StreamSubscription<T> subscr;

  T? value;

  @override
  @override
  void initState() {
    super.initState();

    subscr = widget.statistics.$2(
      (e) {
        setState(() {
          value = e;
        });
      },
      true,
    );
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final values = widget.statistics.$1(value as T);

    return SizedBox(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ...values.take(values.length - 1).fold<List<Widget>>([], (v, w) {
            v.add(w);
            v.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "・",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.15),
                  ),
                ),
              ),
            );

            return v;
          }),
          values.last,
        ],
      ),
    );
  }
}

class StatisticsCard extends StatelessWidget {
  const StatisticsCard({
    super.key,
    required this.subtitle,
    required this.title,
  });

  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$subtitle\n",
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
          TextSpan(
            text: title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
