// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/logic/blacklisted_directories_mixin.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:azari/src/ui/material/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class BlacklistedDirectoriesPage extends StatefulWidget {
  const BlacklistedDirectoriesPage({
    super.key,
    required this.popScope,
    required this.selectionController,
    required this.footer,
  });

  final void Function(bool) popScope;
  final SelectionController selectionController;

  final PreferredSizeWidget? footer;

  @override
  State<BlacklistedDirectoriesPage> createState() =>
      _BlacklistedDirectoriesPageState();
}

class _BlacklistedDirectoriesPageState extends State<BlacklistedDirectoriesPage>
    with
        SettingsWatcherMixin,
        BlacklistedDirectoriesMixin,
        BlacklistedDirectoryService {
  @override
  SelectionController get selectionController => widget.selectionController;

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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
