// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/empty_widget.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:flutter/material.dart";

class HiddenPostsPage extends StatefulWidget {
  const HiddenPostsPage({
    super.key,
    required this.db,
  });

  final HiddenBooruPostService db;

  @override
  State<HiddenPostsPage> createState() => HiddenPostsPageState();
}

class HiddenPostsPageState extends State<HiddenPostsPage>
    with CommonGridData<Post, HiddenPostsPage> {
  HiddenBooruPostService get hiddenBooruPost => widget.db;

  final _hideKey = GlobalKey<_HideBlacklistedImagesHolderState>();

  late final source = GenericListSource<HiddenBooruPostData>(
    () => Future.value(
      hiddenBooruPost.cachedValues.entries
          .map(
            (e) => HiddenBooruPostData(
              booru: e.key.$2,
              postId: e.key.$1,
              thumbUrl: e.value,
            ),
          )
          .toList(),
    ),
  );

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.list,
  );

  @override
  void dispose() {
    gridSettings.cancel();
    source.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _HideBlacklistedImagesHolder(
      key: _hideKey,
      child: GridConfiguration(
        watch: gridSettings.watch,
        child: GridFrame<HiddenBooruPostData>(
          key: gridKey,
          slivers: [
            ListLayout<HiddenBooruPostData>(
              hideThumbnails: false,
              source: source.backingStorage,
              progress: source.progress,
              itemFactory: (context, index, cell) {
                final extras =
                    GridExtrasNotifier.of<HiddenBooruPostData>(context);

                return DefaultListTile(
                  functionality: extras.functionality,
                  selection: extras.selection,
                  index: index,
                  cell: cell,
                  trailing: Text(cell.booru.string),
                  hideThumbnails: HideHiddenImagesThumbsNotifier.of(context),
                  dismiss: TileDismiss(
                    () {
                      hiddenBooruPost.removeAll([(cell.postId, cell.booru)]);

                      source.clearRefresh();
                    },
                    Icons.image_rounded,
                  ),
                );
              },
            ),
          ],
          functionality: GridFunctionality(
            onEmptySource: EmptyWidgetBackground(
              subtitle: l10n.emptyHiddenPosts,
            ),
            search: PageNameSearchWidget(
              trailingItems: [
                Builder(
                  builder: (context) {
                    return IconButton(
                      onPressed: () {
                        _hideKey.currentState?.toggle();
                      },
                      icon: HideHiddenImagesThumbsNotifier.of(context)
                          ? const Icon(Icons.image_rounded)
                          : const Icon(Icons.hide_image_rounded),
                    );
                  },
                ),
              ],
              leading: IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            source: source,
          ),
          description: GridDescription(
            pullToRefresh: false,
            pageName: l10n.hiddenPostsPageName,
            gridSeed: gridSeed,
          ),
        ),
      ),
    );
  }
}

class _HideBlacklistedImagesHolder extends StatefulWidget {
  const _HideBlacklistedImagesHolder({
    required super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<_HideBlacklistedImagesHolder> createState() =>
      _HideBlacklistedImagesHolderState();
}

class _HideBlacklistedImagesHolderState
    extends State<_HideBlacklistedImagesHolder> {
  bool show = true;

  void toggle() {
    setState(() {
      show = !show;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HideHiddenImagesThumbsNotifier(hiding: show, child: widget.child);
  }
}

class HideHiddenImagesThumbsNotifier extends InheritedWidget {
  const HideHiddenImagesThumbsNotifier({
    super.key,
    required this.hiding,
    required super.child,
  });
  final bool hiding;

  static bool of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<HideHiddenImagesThumbsNotifier>();

    return widget!.hiding;
  }

  @override
  bool updateShouldNotify(HideHiddenImagesThumbsNotifier oldWidget) =>
      hiding != oldWidget.hiding;
}
