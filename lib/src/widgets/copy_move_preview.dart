// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:gallery/src/widgets/image_view/image_view.dart";

class CopyMovePreview extends StatefulWidget {
  const CopyMovePreview({
    super.key,
    required this.files,
    required this.size,
  });

  final List<GalleryFile> files;
  final double size;

  static PreferredSizeWidget hintWidget(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 24, bottom: 12, top: 12, right: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.25),
                      shape: const StadiumBorder(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 16,
                        left: 16,
                        bottom: 4,
                        top: 4,
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color:
                              colorScheme.onSecondaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.only(right: 8)),
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<CopyMovePreview> createState() => _CopyMovePreviewState();
}

class _CopyMovePreviewState extends State<CopyMovePreview> {
  final key = GlobalKey<ImageViewState>();

  int calculateWidth(int i) {
    return widget.size.toInt() + (i * 14);
  }

  Widget _thumbPadding(
    BuildContext context,
    int id,
    CellBase cellData, {
    bool shadow = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: id * 14),
      child: SizedBox(
        height: widget.size,
        width: widget.size,
        child: GridCell(
          cell: cellData,
          imageAlign: Alignment.topCenter,
          hideTitle: true,
          overrideDescription: const CellStaticData(
            tightMode: true,
            circle: true,
            ignoreStickers: true,
          ),
        ),
      ),
    );
  }

  List<Widget> _previewsLimited(BuildContext context) {
    final list = <Widget>[];

    final width = MediaQuery.sizeOf(context).width - 8;

    for (final e in widget.files.indexed) {
      if (calculateWidth(e.$1) > width) {
        break;
      }

      list.add(_thumbPadding(context, e.$1, e.$2, shadow: e.$1 != 0));
    }

    return list.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: widget.size - 4,
      child: Center(
        child: Badge.count(
          count: widget.files.length,
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, left: 4, bottom: 4),
            child: Stack(
              children: _previewsLimited(context),
            ),
          ),
        ),
      ),
    );
  }
}
