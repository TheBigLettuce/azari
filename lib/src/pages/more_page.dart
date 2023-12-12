// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/pages/blacklisted_posts.dart';
import 'package:gallery/src/pages/notes_page.dart';

import '../widgets/skeletons/drawer/azari_icon.dart';
import 'dashboard.dart';
import 'downloads.dart';
import 'settings/blacklisted_directores.dart';
import 'settings/settings_widget.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AzariIcon(color: Theme.of(context).colorScheme.primary),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.dashboard_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text("Dashboard"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const Dashboard();
                },
              ));
            },
          ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.notes_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text("Notes"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const NotesPage();
                },
              ));
            },
          ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.download_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.downloadsPageName),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const Scaffold(
                    body: Downloads(),
                  );
                },
              ));
            },
          ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.hide_image_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
                AppLocalizations.of(context)!.blacklistedDirectoriesPageName),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlacklistedDirectories(),
                  ));
            },
          ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.hide_image_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text("Blacklisted Posts"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlacklistedPostsPage(),
                  ));
            },
          ),
          const Divider(),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.settingsPageName),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const Scaffold(
                    body: SettingsWidget(),
                  );
                },
              ));
            },
          )
        ],
      ),
    );
  }
}
