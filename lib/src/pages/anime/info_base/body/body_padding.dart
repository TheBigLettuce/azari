// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";

class BodyPadding extends StatelessWidget {
  const BodyPadding({
    super.key,
    required this.viewPadding,
    required this.child,
    this.sliver = false,
  });
  final Widget child;
  final EdgeInsets viewPadding;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.only(
      left: 22,
      right: 22,
    );

    return sliver
        ? SliverPadding(
            padding: padding,
            sliver: child,
          )
        : Padding(
            padding: padding,
            child: child,
          );
  }
}
