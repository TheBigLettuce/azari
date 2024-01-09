// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class _SegmentConstrained extends StatelessWidget {
  // final String label;
  // final String content;
  final AnimeEntry entry;
  final AnimeAPI api;
  final BoxConstraints constraints;

  const _SegmentConstrained({
    super.key,
    required this.entry,
    required this.api,
    this.constraints = const BoxConstraints(maxWidth: 200, maxHeight: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      // mainAxisSize: MainAxisSize.min,

      // : MainAxisAlignment.center,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.vertical,
      children: [
        _Label(text: "Synopsis"),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4, right: 4),
          child: AnimatedContainer(
            duration: 200.ms,
            constraints: constraints,
            child: Text(
              entry.synopsis,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        ),
        if (entry.background.isNotEmpty) _Label(text: "Background"),
        if (entry.background.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4, right: 4),
            child: AnimatedContainer(
              duration: 200.ms,
              constraints: constraints,
              child: Text(
                entry.background,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8)),
              ),
            ),
          ),
      ],
    );
  }
}
