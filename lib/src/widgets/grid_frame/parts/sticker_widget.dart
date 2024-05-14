// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/interfaces/cell/sticker.dart";

class StickerWidget extends StatelessWidget {
  const StickerWidget(
    this.e, {
    super.key,
    this.onPressed,
    this.size = 28,
    this.iconSize = 20,
  });

  final Sticker e;
  final void Function()? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: size,
        width: size,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: e.important
                ? colorScheme.onPrimary.withOpacity(0.9)
                : colorScheme.surfaceContainerHighest.withOpacity(0.8),
          ),
          child: Icon(
            e.icon,
            size: iconSize,
            color: e.important
                ? colorScheme.primary.withOpacity(0.9)
                : colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
