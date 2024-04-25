// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_back_button_behaviour.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

class GridAppBarLeading extends StatelessWidget {
  const GridAppBarLeading({
    super.key,
    required this.state,
  });
  final GridFrameState state;

  @override
  Widget build(BuildContext context) {
    final backBehaviour = state.widget.functionality.backButton;

    return switch (backBehaviour) {
      CountGridBackButton() => IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Badge.count(
            count: backBehaviour.count,
            child: const Icon(Icons.arrow_back),
          ),
        ),
      OverrideGridBackButton() => backBehaviour.child,
      EmptyGridBackButton() => const SizedBox.shrink(),
      CallbackGridBackButton() => IconButton(
          onPressed: backBehaviour.onPressed,
          icon: const Icon(Icons.arrow_back),
        ),
    };
  }
}
