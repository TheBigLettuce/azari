// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/widgets/grid_cell/cell.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";

@immutable
abstract class DownloadFileDataImpl
    with DefaultBuildCellImpl
    implements DownloadFileData {
  const DownloadFileDataImpl();

  @override
  String toString() => "Download${status.name}: $name, url: $url";

  @override
  Key uniqueKey() => ValueKey(url);

  @override
  ImageProvider<Object> thumbnail(BuildContext? context) =>
      CachedNetworkImageProvider(thumbUrl);

  @override
  String alias(bool isList) => name;

  @override
  CellStaticData description() => const CellStaticData();
}
