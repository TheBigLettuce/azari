// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/booru/search.dart';
import 'package:gallery/src/directories.dart';
import 'package:gallery/src/lost_downloads.dart';
import 'settings.dart';

Widget makeDrawer(BuildContext context, bool showBooru, bool showGallery) {
  AnimationController? iconController;

  return Drawer(
    child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
          child: Center(
        child: GestureDetector(
          onTap: () {
            if (iconController != null) {
              iconController!.forward(from: 0);
            }
          },
          child: const Icon(
            IconData(0x963F),
          ),
        ).animate(
            onInit: (controller) => iconController = controller,
            effects: [ShakeEffect(duration: 700.milliseconds, hz: 6)]),
      )),
      if (showGallery)
        if (showBooru)
          ListTile(
            style: ListTileStyle.drawer,
            title: const Text("Booru"),
            leading: const Icon(Icons.image),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
      if (showGallery)
        if (!showBooru)
          ListTile(
            style: ListTileStyle.drawer,
            title: const Text("Gallery"),
            leading: const Icon(Icons.photo_album),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const Directories();
              }));
            },
          ),
      ListTile(
          style: ListTileStyle.drawer,
          title: const Text("Tags"),
          leading: const Icon(Icons.tag),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchBooru(),
                ));
          }),
      ListTile(
        style: ListTileStyle.drawer,
        title: const Text("Downloads"),
        leading: const Icon(Icons.download),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LostDownloads(),
              ));
        },
      ),
      ListTile(
        style: ListTileStyle.drawer,
        title: const Text("Settings"),
        leading: const Icon(Icons.settings),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const Settings()));
        },
      )
    ]),
  );
}
