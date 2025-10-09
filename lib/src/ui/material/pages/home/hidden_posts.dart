// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/cancellable_grid_settings_data.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_aspect_ratio.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/grid_column.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class HiddenPostsPage extends StatefulWidget {
  const HiddenPostsPage({super.key});

  static bool hasServicesRequired() => HiddenBooruPostsService.available;

  static void open(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (context) => const HiddenPostsPage()),
    );
  }

  @override
  State<HiddenPostsPage> createState() => HiddenPostsPageState();
}

class HiddenPostsPageState extends State<HiddenPostsPage>
    with SettingsWatcherMixin, HiddenBooruPostsService {
  final actions = SelectionActions();

  late final source = GenericListSource<HiddenBooruPostData>(
    () => Future.value(
      cachedValues.entries
          .map(
            (e) => HiddenBooruPostData(
              booru: e.key.$2,
              postId: e.key.$1,
              thumbUrl: e.value,
            ),
          )
          .toList(),
    ),
    watchCount: const HiddenBooruPostsService().watch,
  );

  late final SourceShellScopeElementState<HiddenBooruPostData> status;

  final gridSettings = CancellableGridSettingsData.noPersist(
    hideName: false,
    aspectRatio: GridAspectRatio.one,
    columns: GridColumn.three,
    layoutType: GridLayoutType.list,
  );

  @override
  void initState() {
    super.initState();

    status = SourceShellScopeElementState(
      source: source,
      gridSettings: gridSettings,
      onEmpty: SourceOnEmptyInterface(
        source,
        (context) => context.l10n().emptyHiddenPosts,
      ),
      selectionController: actions.controller,
      actions: const [],
      wrapRefresh: null,
    );
  }

  @override
  void dispose() {
    actions.dispose();
    status.destroy();
    gridSettings.cancel();
    source.destroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ScaffoldWithSelectionBar(
      actions: actions,
      child: ShellScope(
        stackInjector: status,
        appBar: TitleAppBarType(title: l10n.hiddenPostsPageName),
        elements: [
          ElementPriority(
            ShellElement(
              state: status,
              gridSettings: gridSettings,
              slivers: [
                ListLayout<HiddenBooruPostData>(
                  hideThumbnails: false,
                  source: source.backingStorage,
                  progress: source.progress,
                  selection: status.selection,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
