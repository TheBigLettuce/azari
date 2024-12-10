// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:math";

import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";

class _PatternPart {
  const _PatternPart(this.pieces);
  final List<QuiltedGridTile> pieces;
}

extension _PatternPartsToListExtension on List<_PatternPart> {
  List<QuiltedGridTile> mergeParts(int seed) {
    final l = toList();
    l.shuffle(Random(seed));

    final l2 = <QuiltedGridTile>[];
    for (final e in l) {
      l2.addAll(e.pieces);
    }

    return l2;
  }
}

enum GridColumn {
  two(2),
  three(3),
  four(4),
  five(5),
  six(6);

  const GridColumn(this.number);

  final int number;

  static GridColumn fromIndex(int idx) => switch (idx) {
        0 => GridColumn.two,
        1 => GridColumn.three,
        2 => GridColumn.four,
        3 => GridColumn.five,
        4 => GridColumn.six,
        int() => GridColumn.two,
      };

  List<QuiltedGridTile> pattern(int gridSeed) => switch (this) {
        GridColumn.two => const [
            _PatternPart([
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
            ]),
            //
            _PatternPart([
              QuiltedGridTile(2, 2),
            ]),
            //
            _PatternPart([
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
            ]),
          ],
        GridColumn.three => const [
            _PatternPart([
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
            ]),

            //
            _PatternPart([
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 2),
            ]),

            //
            _PatternPart([
              QuiltedGridTile(2, 3),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
            ]),

            //
            _PatternPart([
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
            ]),
          ],
        GridColumn.four => const [
            //
            _PatternPart([
              QuiltedGridTile(1, 4),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
            ]),

            //
            _PatternPart([
              QuiltedGridTile(2, 2),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
            ]),
            //
            _PatternPart([
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
            ]),
            //
            _PatternPart([
              QuiltedGridTile(2, 3),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
            ]),
          ],
        GridColumn.five => const [
            _PatternPart([
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
            ]),
            //
            _PatternPart([
              QuiltedGridTile(3, 1),
              QuiltedGridTile(2, 2),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 3),
            ]),
            //
            _PatternPart([
              QuiltedGridTile(3, 3),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 2),
              QuiltedGridTile(1, 3),
            ]),
            //
            _PatternPart([
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(3, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 3),
              QuiltedGridTile(1, 1),
            ]),
          ],
        GridColumn.six => const [
            // full block 3 line
            _PatternPart([
              QuiltedGridTile(3, 3),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
            ]),

            // stripe 1 line
            _PatternPart([
              //   // QuiltedGridTile(1, 3),
              // // QuiltedGridTile(1, 1),
              // // QuiltedGridTile(1, 2),
            ]),
            // full block 2 line
            _PatternPart([
              QuiltedGridTile(2, 2),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
            ]),

            // stripe 1 line
            _PatternPart([
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 3),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
            ]),
            // full block 4 line
            _PatternPart([
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(4, 4),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
            ]),

            // stripe 1 line
            _PatternPart([
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
            ]),
            // full block 2 line
            _PatternPart([
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(2, 1),
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
            ]),

            // stripe 1 line
            _PatternPart([
              QuiltedGridTile(1, 2),
              QuiltedGridTile(1, 3),
              QuiltedGridTile(1, 1),
            ]),

            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 1),

            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 1),

            // QuiltedGridTile(1, 3),

            // QuiltedGridTile(3, 3),

            //
            // QuiltedGridTile(3, 3),
            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 2),
            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 2),
            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 1),
            // QuiltedGridTile(1, 1),

            // QuiltedGridTile(1, 1),
          ],
      }
          .mergeParts(gridSeed);
}
