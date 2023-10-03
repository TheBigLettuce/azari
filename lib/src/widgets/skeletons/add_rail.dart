// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:io';

import 'package:flutter/material.dart';

import 'drawer/azari_icon.dart';
import 'drawer/destinations.dart';
import 'drawer/select_destination.dart';

Widget addRail(BuildContext context, int selectedIndex,
    GlobalKey<ScaffoldState> key, Widget child) {
  if (Platform.isAndroid || Platform.isIOS) {
    return child;
  }

  return Row(
    children: [
      NavigationRail(
          groupAlignment: -0.8,
          leading: azariIcon(context),
          trailing: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                key.currentState?.openEndDrawer();
              },
            ),
          ),
          labelType: NavigationRailLabelType.selected,
          onDestinationSelected: (value) {
            if (value == selectedIndex) {
              return;
            }
            selectDestination(context, selectedIndex, value);
          },
          destinations: [
            ...destinations(context).map((e) => NavigationRailDestination(
                icon: e.icon, label: e.label, selectedIcon: e.selectedIcon))
          ],
          selectedIndex: selectedIndex),
      Expanded(child: child)
    ],
  );
}
