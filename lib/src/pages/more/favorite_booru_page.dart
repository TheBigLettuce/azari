// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/post_base.dart';
import 'package:gallery/src/db/schemas/grid_settings/favorites.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_frame_settings_button.dart';
import 'package:gallery/src/pages/more/favorite_booru_actions.dart';
import 'package:gallery/src/net/downloader.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/booru/favorite_booru.dart';
import 'package:gallery/src/db/schemas/tags/local_tag_dictionary.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layout_behaviour.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/image_view_description.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/grid_frame/layouts/segment_layout.dart';
import 'package:gallery/src/widgets/grid_frame/wrappers/wrap_grid_page.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/search_bar/search_filter_grid.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/loaders/linear_isar_loader.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../booru/booru_grid_actions.dart';
import '../../db/tags/post_tags.dart';
import '../../db/schemas/downloader/download_file.dart';

class FavoriteBooruPage extends StatelessWidget {
  final FavoriteBooruPageState state;
  final ScrollController conroller;
  final bool asSliver;
  final EdgeInsets? viewInsets;
  final bool wrapGridPage;

  const FavoriteBooruPage({
    super.key,
    required this.state,
    required this.conroller,
    this.asSliver = true,
    this.viewInsets,
    this.wrapGridPage = false,
  });

  Widget child(BuildContext context, EdgeInsets insets) {
    final glue = GlueProvider.of<FavoriteBooru>(context);

    return GridFrame<FavoriteBooru>(
      key: state.state.gridKey,
      layout: state.segments != null
          ? SegmentLayout<FavoriteBooru>(
              Segments(
                AppLocalizations.of(context)!.segmentsUncategorized,
                injectedLabel: '',
                hidePinnedIcon: true,
                prebuiltSegments: state.segments,
              ),
              GridSettingsFavorites.current,
            )
          : const GridSettingsLayoutBehaviour(GridSettingsFavorites.current),
      refreshingStatus: state.state.refreshingStatus,
      overrideController: conroller,
      imageViewDescription: ImageViewDescription(
        addIconsImage: (p) => state.iconsImage(p),
        overrideDrawerLabel:
            state.state.settings.buddhaMode ? "Tags" : null, // TODO: change
        imageViewKey: state.state.imageViewKey,
      ),
      functionality: GridFunctionality(
        search: asSliver
            ? const EmptyGridSearchWidget()
            : OverrideGridSearchWidget(
                SearchAndFocus(
                    state.search.searchWidget(
                      context,
                      count: state.state.refreshingStatus.mutation.cellCount,
                    ),
                    state.search.searchFocus),
              ),
        selectionGlue: glue,
        watchLayoutSettings: GridSettingsFavorites.watch,
        download: state.download,
        refresh: SynchronousGridRefresh(() => state.loader.count()),
      ),
      getCell: state.loader.getCell,
      systemNavigationInsets: insets,
      mainFocus: state.state.mainFocus,
      description: GridDescription(
        appBarSnap: !state.state.settings.buddhaMode,
        actions: state.gridActions(),
        settingsButton: !asSliver ? state.gridSettingsButton() : null,
        showAppBar: !asSliver,
        asSliver: asSliver,
        ignoreEmptyWidgetOnNoContent: false,
        ignoreSwipeSelectGesture: false,
        keybindsDescription: AppLocalizations.of(context)!.favoritesLabel,
        pageName: AppLocalizations.of(context)!.favoritesLabel,
        gridSeed: state.state.gridSeed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = viewInsets ?? MediaQuery.viewPaddingOf(context);

    return wrapGridPage
        ? WrapGridPage<FavoriteBooru>(
            scaffoldKey: state.state.scaffoldKey,
            child: Builder(
              builder: (context) => child(context, insets),
            ),
          )
        : child(context, insets);
  }
}

class FavoriteBooruStateHolder extends StatefulWidget {
  final Widget Function(BuildContext context, FavoriteBooruPageState state)
      build;

  const FavoriteBooruStateHolder({
    super.key,
    required this.build,
  });

  @override
  State<FavoriteBooruStateHolder> createState() =>
      _FavoriteBooruStateHolderState();
}

class _FavoriteBooruStateHolderState extends State<FavoriteBooruStateHolder>
    with FavoriteBooruPageState {
  @override
  void initState() {
    super.initState();

    initFavoriteBooruState();
  }

  @override
  void dispose() {
    disposeFavoriteBooruState();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, this);
  }
}

class _FilterEnumSegmentKey implements SegmentKey {
  const _FilterEnumSegmentKey(this.mode);

  final FilteringMode mode;

  @override
  String translatedString(BuildContext context) =>
      mode.translatedString(context);

  @override
  int get hashCode => mode.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _FilterEnumSegmentKey) {
      return false;
    }

    return other.mode == mode;
  }
}

class _StringSegmentKey implements SegmentKey {
  const _StringSegmentKey(this.string);

  final String string;

  @override
  String translatedString(BuildContext context) => string;

  @override
  int get hashCode => string.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _StringSegmentKey) {
      return false;
    }

    return other.string == string;
  }
}

mixin FavoriteBooruPageState<T extends StatefulWidget> on State<T> {
  late final StreamSubscription favoritesWatcher;
  late final StreamSubscription<MiscSettings?> miscSettingsWatcher;

  final booru = Settings.fromDb().selectedBooru;

  MiscSettings miscSettings = MiscSettings.current;

  Map<SegmentKey, int>? segments;

  bool segmented = false;

  late final loader = LinearIsarLoader<FavoriteBooru>(
      FavoriteBooruSchema, Dbs.g.main, (offset, limit, s, sort, mode) {
    if (mode == FilteringMode.group) {
      if (s.isEmpty) {
        return Dbs.g.main.favoriteBoorus
            .where()
            .sortByGroupDesc()
            .thenByCreatedAtDesc()
            .offset(offset)
            .limit(limit)
            .findAllSync();
      }

      return Dbs.g.main.favoriteBoorus
          .filter()
          .groupContains(s)
          .sortByGroupDesc()
          .thenByCreatedAtDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    } else if (mode == FilteringMode.same) {
      return Dbs.g.main.favoriteBoorus
          .filter()
          .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
          .sortByMd5()
          .thenByCreatedAtDesc()
          .offset(offset)
          .limit(limit)
          .findAllSync();
    }

    return Dbs.g.main.favoriteBoorus
        .filter()
        .allOf(s.split(" "), (q, element) => q.tagsElementContains(element))
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAllSync();
  })
    ..filter.passFilter = (cells, data, end) {
      final filterMode = search.currentFilteringMode();

      if (filterMode == FilteringMode.group) {
        segments = segments ?? {};

        for (final e in cells) {
          if (e.group != null) {
            segments![_StringSegmentKey(e.group!)] =
                (segments![_StringSegmentKey(e.group!)] ?? 0) + 1;

            continue;
          }

          segments![const _FilterEnumSegmentKey(FilteringMode.ungrouped)] =
              (segments![const _FilterEnumSegmentKey(
                          FilteringMode.ungrouped)] ??
                      0) +
                  1;
        }
      } else {
        segments = null;
      }

      return switch (filterMode) {
        FilteringMode.same => sameFavorites(cells, data, end, _collector),
        FilteringMode.ungrouped => (
            cells.where(
                (element) => element.group == null || element.group!.isEmpty),
            data
          ),
        FilteringMode.gif => (
            cells.where((element) => element.content is NetGif),
            data
          ),
        FilteringMode.video => (
            cells.where((element) => element.content is NetVideo),
            data
          ),
        FilteringMode() => (cells, data)
      };
    };

  Iterable<FavoriteBooru> _collector(Map<String, Set<String>>? data) {
    return () sync* {
      for (final ids in data!.values) {
        for (final i in ids) {
          final f = loader.instance.favoriteBoorus.getByFileUrlSync(i)!;
          f.isarId = null;
          yield f;
        }
      }
    }();
  }

  static (Iterable<T>, dynamic) sameFavorites<T extends PostBase>(
      Iterable<T> cells,
      Map<String, Set<String>>? data,
      bool end,
      Iterable<T> Function(Map<String, Set<String>>? data) collect) {
    data = data ?? {};

    T? prevCell;
    for (final e in cells) {
      if (prevCell != null) {
        if (prevCell.md5 == e.md5) {
          final prev = data[e.md5] ?? {prevCell.fileUrl};

          data[e.md5] = {...prev, e.fileUrl};
        }
      }

      prevCell = e;
    }

    if (end) {
      return (collect(data), null);
    }

    return (const [], data);
  }

  late final state = GridSkeletonStateFilter<FavoriteBooru>(
    filter: loader.filter,
    unsetFilteringModeOnReset: false,
    hook: (selected) {
      segments = null;
      if (selected == FilteringMode.group) {
        segmented = true;
        setState(() {});
      } else {
        segmented = false;
        setState(() {});
      }

      MiscSettings.setFavoritesPageMode(selected);
    },
    defaultMode: FilteringMode.tag,
    filteringModes: {
      FilteringMode.tag,
      FilteringMode.group,
      FilteringMode.ungrouped,
      FilteringMode.gif,
      FilteringMode.video,
      FilteringMode.same,
    },
    transform: (FavoriteBooru cell) {
      return cell;
    },
  );

  late final SearchFilterGrid<FavoriteBooru> search;

  void disposeFavoriteBooruState() {
    miscSettingsWatcher.cancel();
    favoritesWatcher.cancel();

    state.dispose();
    search.dispose();
  }

  void initFavoriteBooruState() {
    search = SearchFilterGrid(state, null);

    search.setFilteringMode(miscSettings.favoritesPageMode);
    search.setLocalTagCompleteF((string) {
      final result = Dbs.g.main.localTagDictionarys
          .filter()
          .tagContains(string)
          .sortByFrequencyDesc()
          .limit(10)
          .findAllSync();

      return Future.value(result.map((e) => e.tag).toList());
    });

    setState(() {});

    miscSettingsWatcher = MiscSettings.watch((s) {
      miscSettings = s!;

      setState(() {});
    });

    favoritesWatcher = FavoriteBooru.watch((event) {
      search.performSearch(search.searchTextController.text, true);

      state.gridKey.currentState?.selection.reset();
    });

    search.prewarmResults();
  }

  List<GridAction<FavoriteBooru>> iconsImage(FavoriteBooru p) {
    return [
      BooruGridActions.favorites(context, p, showDeleteSnackbar: true),
      BooruGridActions.download(context, booru),
      _groupButton(context)
    ];
  }

  Future<void> download(int i) async {
    final p = loader.getCell(i);

    PostTags.g.addTagsPost(p.filename(), p.tags, true);

    return Downloader.g.add(
        DownloadFile.d(
            url: p.fileDownloadUrl(),
            site: booru.url,
            name: p.filename(),
            thumbUrl: p.previewUrl),
        state.settings);
  }

  GridAction<FavoriteBooru> _groupButton(BuildContext context) {
    return FavoritesActions.addToGroup(
      context,
      (selected) {
        final g = selected.first.group;
        for (final e in selected.skip(1)) {
          if (g != e.group) {
            return null;
          }
        }

        return g;
      },
      (selected, value, toPin) {
        for (final e in selected) {
          e.group = value.isEmpty ? null : value;
        }

        FavoriteBooru.addAllFileUrl(selected);

        Navigator.of(context, rootNavigator: true).pop();
      },
      false,
    );
  }

  List<GridAction<FavoriteBooru>> gridActions() {
    return [
      BooruGridActions.download(context, booru),
      _groupButton(context),
      BooruGridActions.favorites(
        context,
        null,
        showDeleteSnackbar: true,
      ),
    ];
  }

  GridFrameSettingsButton gridSettingsButton() {
    return GridFrameSettingsButton(
      selectHideName: null,
      overrideDefault: GridSettingsFavorites.current,
      watchExplicitly: GridSettingsFavorites.watch,
      selectRatio: (ratio, settings) =>
          (settings as GridSettingsFavorites).copy(aspectRatio: ratio).save(),
      selectGridLayout: (layoutType, settings) =>
          (settings as GridSettingsFavorites)
              .copy(layoutType: layoutType)
              .save(),
      selectGridColumn: (columns, settings) =>
          (settings as GridSettingsFavorites).copy(columns: columns).save(),
    );
  }
}
