// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/state_restoration.dart';
import 'package:gallery/src/interfaces/booru/booru_api_state.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/pages/more/blacklisted_posts.dart';
import 'package:gallery/src/pages/more/tags/tags_page.dart';

import '../../widgets/skeletons/drawer/azari_icon.dart';
import 'dashboard/dashboard.dart';
import 'downloads.dart';
import 'settings/blacklisted_directores.dart';
import 'settings/settings_widget.dart';

class MorePage extends StatelessWidget {
  final TagManager<Unrestorable> tagManager;
  final BooruAPIState api;
  // final SelectionGlue<SystemGalleryDirectoryFile> glue;
  final SelectionGlue<J> Function<J extends Cell>() generateGlue;

  const MorePage({
    super.key,
    required this.api,
    required this.tagManager,
    required this.generateGlue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AzariIcon(color: Theme.of(context).colorScheme.primary),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ListTile(
          //   style: ListTileStyle.drawer,
          //   leading: Icon(
          //     Icons.tag,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          //   title: Text(AppLocalizations.of(context)!.tagsLabel),
          //   onTap: () {
          //     Navigator.push(context, MaterialPageRoute(
          //       builder: (context) {
          //         return TagsPage(
          //           tagManager: tagManager,
          //           booru: api,
          //           generateGlue: generateGlue,
          //         );
          //       },
          //     ));
          //   },
          // ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.dashboard_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.dashboardPage),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const Dashboard();
                },
              ));
            },
          ),
          // ListTile(
          //   style: ListTileStyle.drawer,
          //   leading: Icon(
          //     Icons.notes_outlined,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          //   title: Text(AppLocalizations.of(context)!.notesPage),
          //   onTap: () {
          //     Navigator.push(context, MaterialPageRoute(
          //       builder: (context) {
          //         return const NotesPage();
          //       },
          //     ));
          //   },
          // ),
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
                  return Downloads(
                    generateGlue: generateGlue,
                    glue: generateGlue(),
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
                    builder: (context) => BlacklistedDirectories(
                      generateGlue: generateGlue,
                      glue: generateGlue(),
                    ),
                  ));
            },
          ),
          ListTile(
            style: ListTileStyle.drawer,
            leading: Icon(
              Icons.hide_image_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(AppLocalizations.of(context)!.blacklistedPostsPageName),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlacklistedPostsPage(
                      generateGlue: generateGlue,
                      glue: generateGlue(),
                    ),
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
              Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                builder: (context) {
                  return const SettingsWidget();
                },
              ));
            },
          )
        ],
      ),
    );
  }
}
