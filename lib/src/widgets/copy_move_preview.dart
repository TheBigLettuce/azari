// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';

import '../cell/cell.dart';
import '../pages/image_view.dart';
import '../schemas/android_gallery_directory_file.dart';
import 'grid/cell.dart';

const kCopyMoveSize = 52.0;

class CopyMovePreview extends StatefulWidget {
  final List<SystemGalleryDirectoryFile> files;
  const CopyMovePreview({super.key, required this.files});

  @override
  State<CopyMovePreview> createState() => _CopyMovePreviewState();
}

class _CopyMovePreviewState extends State<CopyMovePreview> {
  final key = GlobalKey<ImageViewState>();

  int calculateWidth(int i) {
    return kCopyMoveSize.toInt() + (i * 14);
  }

  Widget _thumbPadding(int id, Cell cellData, {bool shadow = true}) {
    return Padding(
      padding: EdgeInsets.only(left: id * 14),
      child: SizedBox(
        height: kCopyMoveSize,
        width: kCopyMoveSize,
        child: GridCell(
          cell: cellData.getCellData(false),
          indx: id,
          ignoreStickers: true,
          onPressed: (context) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ImageView<Cell>(
                  key: key,
                  systemOverlayRestoreColor:
                      Theme.of(context).colorScheme.background.withOpacity(0.5),
                  updateTagScrollPos: (_, __) {},
                  scrollUntill: (_) {},
                  onExit: () {},
                  addIcons: (_) {
                    return [
                      GridBottomSheetAction(Icons.close_rounded, (_) {
                        widget.files.removeAt(key.currentState!.currentPage);

                        key.currentState!.update(widget.files.length);

                        if (widget.files.isEmpty) {
                          Navigator.pop(context);
                        }

                        setState(() {});
                      },
                          false,
                          const GridBottomSheetActionExplanation(
                            label: "Exclude", // TODO: change
                            body:
                                "Exclude the file from the selected.", // TODO: change
                          ))
                    ];
                  },
                  focusMain: () {},
                  getCell: (i) => widget.files[i],
                  cellCount: widget.files.length,
                  startingCell: id,
                  onNearEnd: null);
            }));
          },
          tight: true,
          download: null,
          hidealias: true,
          shadowOnTop: shadow,
          circle: true,
        ),
      ),
    );
  }

  List<Widget> _previewsLimited(BuildContext context) {
    final list = <Widget>[];

    final width = (MediaQuery.sizeOf(context).width - 8);

    for (final e in widget.files.indexed) {
      if (calculateWidth(e.$1) > width) {
        break;
      }

      list.add(_thumbPadding(e.$1, e.$2, shadow: e.$1 != 0));
    }

    return list.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: kCopyMoveSize - 4,
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
