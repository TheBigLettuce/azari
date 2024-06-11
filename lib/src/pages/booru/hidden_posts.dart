// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/impl/memory_only/impl.dart";
import "package:gallery/src/db/services/resource_source/basic.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/widgets/glue_provider.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/layouts/list_layout.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:gallery/src/widgets/skeletons/skeleton_state.dart";

class HiddenPostsPage extends StatefulWidget {
  const HiddenPostsPage({
    super.key,
    required this.generateGlue,
    required this.db,
  });

  final SelectionGlue Function([Set<GluePreferences>]) generateGlue;

  final HiddenBooruPostService db;

  @override
  State<HiddenPostsPage> createState() => HiddenPostsPageState();
}

class HiddenPostsPageState extends State<HiddenPostsPage> {
  HiddenBooruPostService get hiddenBooruPost => widget.db;

  final _hideKey = GlobalKey<_HideBlacklistedImagesHolderState>();

  late final state = GridSkeletonState<HiddenBooruPostData>();
  late final source = GenericListSource<HiddenBooruPostData>(
    () => Future.value(
      hiddenBooruPost.cachedValues.entries
          .map((e) => PlainHiddenBooruPostData(e.key.$2, e.key.$1, e.value))
          .toList(),
    ),
  );

  final gridSettings = GridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.list,
  );

  @override
  void dispose() {
    gridSettings.cancel();
    source.destroy();
    state.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HideBlacklistedImagesHolder(
      key: _hideKey,
      child: GridConfiguration(
        watch: gridSettings.watch,
        child: GlueProvider(
          generate: widget.generateGlue,
          child: GridFrame<HiddenBooruPostData>(
            key: state.gridKey,
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
                  );
                },
              ),
            ],
            functionality: GridFunctionality(
              selectionGlue: widget.generateGlue(),
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
              actions: [
                GridAction(
                  Icons.photo,
                  (selected) {
                    hiddenBooruPost.removeAll(
                      selected.map((e) => (e.postId, e.booru)).toList(),
                    );

                    source.clearRefresh();
                  },
                  true,
                ),
              ],
              keybindsDescription:
                  AppLocalizations.of(context)!.hiddenPostsPageName,
              gridSeed: state.gridSeed,
            ),
          ),
        ),
      ),
    );
  }
}

class _HideBlacklistedImagesHolder extends StatefulWidget {
  const _HideBlacklistedImagesHolder({required super.key, required this.child});

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
