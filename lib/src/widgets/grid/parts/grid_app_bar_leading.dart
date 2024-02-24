// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/grid/configuration/grid_back_button_behaviour.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';

class GridAppBarLeading extends StatelessWidget {
  final GridFrameState state;

  const GridAppBarLeading({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final selection = state.selection;

    if (selection.selected.isNotEmpty) {
      return IconButton(
        onPressed: selection.reset,
        icon: Badge.count(
          count: selection.selected.length,
          child: const Icon(
            Icons.close_rounded,
          ),
        ),
      );
    }

    final backBehaviour = state.widget.functionality.backButton;

    return switch (backBehaviour) {
      DefaultGridBackButton() => IconButton(
          onPressed: selection.reset,
          icon: const Icon(Icons.arrow_back),
        ),
      CountGridBackButton() => IconButton(
          onPressed: selection.reset,
          icon: Badge.count(
            count: backBehaviour.count,
            child: const Icon(Icons.arrow_back),
          ),
        ),
      OverrideGridBackButton() => backBehaviour.child,
    };
  }
}
