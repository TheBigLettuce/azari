// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/common_grid_data.dart";
import "package:azari/src/widgets/selection_bar.dart";
import "package:azari/src/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class HiddenPostsPage extends StatefulWidget {
  const HiddenPostsPage({
    super.key,
    required this.hiddenBooruPosts,
    required this.settingsService,
    required this.selectionController,
  });

  final SelectionController selectionController;

  final HiddenBooruPostsService hiddenBooruPosts;
  final SettingsService settingsService;

  static bool hasServicesRequired(Services db) =>
      db.get<HiddenBooruPostsService>() != null;

  @override
  State<HiddenPostsPage> createState() => HiddenPostsPageState();
}

class HiddenPostsPageState extends State<HiddenPostsPage>
    with CommonGridData<HiddenPostsPage> {
  HiddenBooruPostsService get hiddenBooruPost => widget.hiddenBooruPosts;

  @override
  SettingsService get settingsService => widget.settingsService;

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

  late final SourceShellElementState<HiddenBooruPostData> status;

  final gridSettings = CancellableWatchableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.list,
  );

  @override
  void initState() {
    super.initState();

    status = SourceShellElementState(
      source: source,
      onEmpty: SourceOnEmptyInterface(
        source,
        (context) => context.l10n().emptyHiddenPosts,
      ),
      selectionController: widget.selectionController,
      actions: const [],
      wrapRefresh: null,
    );
  }

  @override
  void dispose() {
    status.destroy();
    gridSettings.cancel();
    source.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return _HideBlacklistedImagesHolder(
      key: _hideKey,
      child: ShellScope(
        stackInjector: status,
        configWatcher: gridSettings.watch,
        appBar: TitleAppBarType(
          title: l10n.hiddenPostsPageName,
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
        elements: [
          ElementPriority(
            ShellElement(
              // key: gridKey,
              state: status,
              slivers: [
                ListLayout<HiddenBooruPostData>(
                  hideThumbnails: false,
                  source: source.backingStorage,
                  progress: source.progress,
                  selection: status.selection,
                  itemFactory: (context, index, cell) {
                    return DefaultListTile(
                      selection: status.selection,
                      index: index,
                      cell: cell,
                      trailing: Text(cell.booru.string),
                      hideThumbnails:
                          HideHiddenImagesThumbsNotifier.of(context),
                      dismiss: TileDismiss(
                        () {
                          hiddenBooruPost
                              .removeAll([(cell.postId, cell.booru)]);

                          source.clearRefresh();
                        },
                        Icons.image_rounded,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
