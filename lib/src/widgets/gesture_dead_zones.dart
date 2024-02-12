// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class GestureDeadZones extends StatelessWidget {
  final bool left;
  final bool right;

  final void Function()? onPressedLeft;
  final void Function()? onPressedRight;

  final Widget child;

  const GestureDeadZones({
    super.key,
    this.left = false,
    this.right = false,
    this.onPressedLeft,
    this.onPressedRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final systemInsets = MediaQuery.systemGestureInsetsOf(context);
    if (systemInsets == EdgeInsets.zero &&
        onPressedLeft == null &&
        onPressedRight == null) {
      return child;
    }

    return Stack(
      children: [
        child,
        if (left || onPressedLeft != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                  top: kToolbarHeight +
                      MediaQuery.systemGestureInsetsOf(context).top),
              child: AbsorbPointer(
                absorbing: onPressedRight == null,
                child: SizedBox(
                    width: systemInsets.left +
                        (onPressedLeft != null
                            ? MediaQuery.sizeOf(context).width * 0.18
                            : 0),
                    child: onPressedLeft != null
                        ? GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: onPressedLeft,
                            child: const SizedBox.expand(),
                          )
                        : Container()),
              ),
            ),
          ),
        if (right || onPressedRight != null)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                  top: kToolbarHeight +
                      MediaQuery.systemGestureInsetsOf(context).top),
              child: AbsorbPointer(
                absorbing: onPressedRight == null,
                child: SizedBox(
                    width: systemInsets.right +
                        (onPressedRight != null
                            ? MediaQuery.sizeOf(context).width * 0.18
                            : 0),
                    child: onPressedRight != null
                        ? GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: onPressedRight,
                            child: const SizedBox.expand(),
                          )
                        : Container()),
              ),
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
}
