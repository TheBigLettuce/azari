// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class _Body extends StatefulWidget {
  final AnimeEntry entry;

  const _Body({super.key, required this.entry});

  @override
  State<_Body> createState() => __BodyState();
}

class __BodyState extends State<_Body> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.sizeOf(context).height * 0.3 +
            kToolbarHeight +
            MediaQuery.viewPaddingOf(context).top,
        left: 8,
        right: 8,
      ),
      child: Center(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 4,
                children: widget.entry.genres
                    .map((e) => Chip(
                          surfaceTintColor:
                              Theme.of(context).colorScheme.surfaceTint,
                          elevation: 4,
                          labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8)),
                          visualDensity: VisualDensity.compact,
                          label: Text(e),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ))
                    .toList(),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            _SegmentConstrained(
              content: widget.entry.synopsis,
              label: "Synopsis",
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
            )
          ],
        ),
      ),
    );
  }
}
