// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";

@immutable
abstract class GridBookmarkImpl
    with DefaultBuildCell, CellBuilderData
    implements CellBuilder, GridBookmark {
  const GridBookmarkImpl();

  @override
  String title(AppLocalizations l10n) => tags;

  @override
  Key uniqueKey() => ValueKey(name);

  @override
  ImageProvider<Object>? thumbnail() {
    if (thumbnails.isEmpty) {
      return null;
    }

    return CachedNetworkImageProvider(thumbnails.first.url);
  }

  @override
  String toString() => "GridBookmarkBase: $name $time";
}
