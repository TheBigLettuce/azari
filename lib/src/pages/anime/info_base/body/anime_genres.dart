// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class AnimeGenres<T> extends StatelessWidget {
  final List<(T, bool)> genres;
  final String Function(T) title;
  final void Function(T) onPressed;

  const AnimeGenres({
    super.key,
    required this.genres,
    required this.onPressed,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 4,
        children: genres
            .map((e) => ActionChip(
                  // backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                  elevation: 4,
                  visualDensity: VisualDensity.compact,
                  label: Text(title(e.$1)),
                  onPressed: e.$2 ? null : () => onPressed.call(e.$1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ))
            .toList(),
      ),
    );
  }
}
