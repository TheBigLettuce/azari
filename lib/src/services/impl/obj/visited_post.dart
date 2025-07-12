// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/services/impl/obj/post_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:azari/src/ui/material/widgets/shell/shell_scope.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";

abstract class VisitedPostImpl
    with DefaultBuildCell, CellBuilderData
    implements VisitedPost {
  const VisitedPostImpl();

  @override
  Key uniqueKey() => ValueKey((booru, id));

  @override
  String title(AppLocalizations context) => id.toString();

  @override
  ImageProvider<Object>? thumbnail() => CachedNetworkImageProvider(thumbUrl);

  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    bool blur = false,
    Alignment imageAlign = Alignment.center,
  }) => Builder(
    key: uniqueKey(),
    builder: (context) => WrapSelection(
      onPressed: () => openPostAsync(context, booru: booru, postId: id),
      child: super.buildCell(
        l10n,
        cellType: cellType,
        hideName: hideName,
        imageAlign: imageAlign,
      ),
    ),
  );
}
