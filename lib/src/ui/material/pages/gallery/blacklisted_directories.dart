// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/services.dart";
import "package:azari/src/logic/blacklisted_directories_mixin.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/ui/material/widgets/common_grid_data.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class BlacklistedDirectoriesPage extends StatefulWidget {
  const BlacklistedDirectoriesPage({
    super.key,
    required this.popScope,
    required this.settingsService,
    required this.blacklistedDirectories,
    required this.selectionController,
    required this.footer,
  });

  final void Function(bool) popScope;
  final SelectionController selectionController;

  final SettingsService settingsService;
  final BlacklistedDirectoryService blacklistedDirectories;

  final PreferredSizeWidget? footer;

  @override
  State<BlacklistedDirectoriesPage> createState() =>
      _BlacklistedDirectoriesPageState();
}

class _BlacklistedDirectoriesPageState extends State<BlacklistedDirectoriesPage>
    with
        CommonGridData<BlacklistedDirectoriesPage>,
        BlacklistedDirectoriesMixin {
  @override
  SelectionController get selectionController => widget.selectionController;

  @override
  BlacklistedDirectoryService get blacklistedDirectories =>
      widget.blacklistedDirectories;

  @override
  SettingsService get settingsService => widget.settingsService;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return ShellScope(
      stackInjector: status,
      configWatcher: gridConfiguration.watch,
      footer: widget.footer,
      appBar: TitleAppBarType(
        title: l10n.blacklistedFoldersPage,
        leading: IconButton(
          onPressed: () => widget.popScope(false),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      elements: [
        ElementPriority(
          ShellElement(
            animationsOnSourceWatch: false,
            state: status,
            slivers: [
              ListLayout<BlacklistedDirectoryData>(
                hideThumbnails: false,
                source: filter.backingStorage,
                progress: filter.progress,
                selection: status.selection,
                itemFactory: (context, idx, cell) {
                  return DefaultListTile(
                    selection: status.selection,
                    index: idx,
                    cell: cell,
                    hideThumbnails: false,
                    dismiss: TileDismiss(
                      () {
                        blacklistedDirectories.backingStorage
                            .removeAll([cell.bucketId]);
                      },
                      Icons.restore_page_rounded,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
