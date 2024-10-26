// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/platform/gallery_api.dart" as gallery;
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:flutter/material.dart";

class CopyMovePreview extends StatefulWidget {
  const CopyMovePreview({
    super.key,
    required this.files,
    required this.title,
    required this.icon,
  });

  final List<gallery.File>? files;
  final String title;
  final IconData icon;

  static const int size = 60 + 16;

  @override
  State<CopyMovePreview> createState() => _CopyMovePreviewState();
}

class _CopyMovePreviewState extends State<CopyMovePreview> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: CopyMovePreview.size.toDouble(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: colorScheme.surfaceContainer.withOpacity(0.95),
          ),
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                bottom: 12,
                top: 12,
                right: 24,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox.square(
                      dimension: 36,
                      child: widget.files != null
                          ? Badge.count(
                              count: widget.files!.length,
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: 4,
                                  left: 4,
                                  bottom: 4,
                                ),
                                child: GridCell(
                                  cell: widget.files!.first,
                                  imageAlign: Alignment.topCenter,
                                  hideTitle: true,
                                  overrideDescription: const CellStaticData(
                                    tightMode: true,
                                    circle: true,
                                    ignoreStickers: true,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                    DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
