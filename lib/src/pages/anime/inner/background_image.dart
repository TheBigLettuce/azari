// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class _BackgroundImage extends StatelessWidget {
  final AnimeEntry entry;

  const _BackgroundImage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height * 0.3 +
          kToolbarHeight +
          MediaQuery.viewPaddingOf(context).top,
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
              Theme.of(context).colorScheme.background.withOpacity(0.6),
              Theme.of(context).colorScheme.background.withOpacity(0.4)
            ]),
      ),
      decoration: BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            opacity: 0.4,
            filterQuality: FilterQuality.high,
            colorFilter:
                const ColorFilter.mode(Colors.black87, BlendMode.softLight),
            image: entry.getCellData(false, context: context).thumb!),
      ),
    );
  }
}
