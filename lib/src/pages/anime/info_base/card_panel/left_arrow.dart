// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeftArrow extends StatelessWidget {
  final bool show;

  const LeftArrow({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Animate(
      target: show ? 1 : 0,
      effects: [
        FadeEffect(
            duration: 200.ms,
            curve: Easing.emphasizedAccelerate,
            begin: 0,
            end: 1)
      ],
      child: Align(
        alignment: Alignment.centerLeft,
        child: Icon(
          Icons.arrow_left,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.2),
        ),
      ),
    );
  }
}
