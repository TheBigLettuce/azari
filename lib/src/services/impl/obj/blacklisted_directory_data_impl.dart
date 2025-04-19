// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/files.dart";
import "package:azari/src/ui/material/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/list_layout.dart";
import "package:flutter/material.dart";

@immutable
abstract class BlacklistedDirectoryDataImpl
    with DefaultBuildCell, CellBuilderData
    implements CellBuilder, BlacklistedDirectoryDataBase {
  const BlacklistedDirectoryDataImpl();

  @override
  Key uniqueKey() => ValueKey(bucketId);

//  itemFactory: (context, idx, cell) {
//                   return cell.buildCell(
//                     context,
//                     cell,
//                     cellType: CellType.list,
//                     wrapSelection: (child) => child,
//                   );
//                 },

  @override
  TileDismiss dismiss() => TileDismiss(
        () {
          const BlacklistedDirectoryService()
              .backingStorage
              .removeAll([bucketId]);
        },
        Icons.restore_page_rounded,
      );

  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    Alignment imageAlign = Alignment.center,
  }) {
    return Builder(
      builder: (context) => InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          final (api, callback, _) = DirectoriesDataNotifier.of(context);

          FilesPage.open(
            context,
            api: api,
            dirName: name,
            callback: callback?.toFileOrNull,
            directories: [
              Directory(
                bucketId: bucketId,
                name: name,
                tag: "",
                volumeName: "",
                relativeLoc: "",
                lastModified: 0,
                thumbFileId: 0,
              ),
            ],
            secure: true,
          );
        },
        child: super.buildCell(
          l10n,
          cellType: cellType,
          hideName: hideName,
          imageAlign: imageAlign,
        ),
      ),
    );
  }

  @override
  String title(AppLocalizations l10n) => name;
}
