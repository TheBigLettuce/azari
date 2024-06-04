// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class AnimeGenres<T> extends StatelessWidget {
  const AnimeGenres({
    super.key,
    required this.genres,
    required this.onPressed,
    required this.title,
    this.sliver = false,
  });
  final List<(T, bool)> genres;
  final String Function(T) title;
  final void Function(T) onPressed;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 4,
          children: genres
              .map(
                (e) => ActionChip(
                  surfaceTintColor: theme.colorScheme.surfaceTint,
                  elevation: 4,
                  visualDensity: VisualDensity.compact,
                  label: Text(title(e.$1)),
                  onPressed: e.$2 ? null : () => onPressed.call(e.$1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    return sliver ? SliverToBoxAdapter(child: child) : child;
  }
}
