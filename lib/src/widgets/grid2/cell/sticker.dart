// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class Sticker {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final bool right;

  const Sticker(this.icon,
      {this.color, this.backgroundColor, this.right = false});
}

class StickerWidget extends StatelessWidget {
  final Sticker e;
  final void Function()? onPressed;

  const StickerWidget(this.e, {super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: e.backgroundColor != null
                ? e.backgroundColor!.withOpacity(0.6)
                : Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
            borderRadius: BorderRadius.circular(5)),
        child: Icon(
          e.icon,
          color: e.color != null
              ? e.color!.withOpacity(0.8)
              : Theme.of(context).colorScheme.secondary.withOpacity(0.8),
        ),
      ),
    );
  }
}
