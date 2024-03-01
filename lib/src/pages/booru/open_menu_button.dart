// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/interfaces/booru/safe_mode.dart';
import 'package:gallery/src/widgets/make_tags.dart';
import 'package:gallery/src/widgets/menu_wrapper.dart';

class OpenMenuButton extends StatelessWidget {
  final void Function(BuildContext, String, [SafeMode?]) launchGrid;
  final TextEditingController controller;
  final Booru booru;
  final BuildContext context;

  const OpenMenuButton({
    super.key,
    required this.controller,
    required this.booru,
    required this.launchGrid,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      // icon: const Icon(Icons.search_rounded),
      itemBuilder: (_) {
        return MenuWrapper.menuItems(controller.text, true, [
          launchGridSafeModeItem(
            context,
            controller.text,
            launchGrid,
          )
        ]);
      },
    );
  }
}
