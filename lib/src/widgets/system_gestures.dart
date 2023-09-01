// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';

Widget gestureDeadZones(BuildContext context,
    {required Widget child, bool left = false, bool right = false}) {
  final systemInsets = MediaQuery.systemGestureInsetsOf(context);
  if (systemInsets == EdgeInsets.zero) {
    return child;
  }

  return Stack(
    children: [
      child,
      if (left)
        Align(
          alignment: Alignment.centerLeft,
          child: AbsorbPointer(
            child: SizedBox(width: systemInsets.left, child: Container()),
          ),
        ),
      if (right)
        Align(
          alignment: Alignment.centerRight,
          child: AbsorbPointer(
            child: SizedBox(width: systemInsets.right, child: Container()),
          ),
        ),
      Align(
        alignment: Alignment.bottomCenter,
        child: AbsorbPointer(
          child: SizedBox(
            height: systemInsets.bottom,
            child: Container(),
          ),
        ),
      )
    ],
  );
}
