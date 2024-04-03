// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/azari_icon.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/selection_glue.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';

import 'dashboard/dashboard.dart';
import 'downloads.dart';
import 'blacklisted_page.dart';
import 'settings/settings_widget.dart';

extension GlueTransformerExt on SelectionGlue Function([Set<GluePreferences>]) {
  SelectionGlue persistentZero([Set<GluePreferences> set = const {}]) {
    return this(
        {GluePreferences.persistentBarHeight, GluePreferences.zeroSize});
  }
}

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AzariIcon(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
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
        ListTile(
          style: ListTileStyle.drawer,
          leading: Icon(
            Icons.download_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(AppLocalizations.of(context)!.downloadsPageName),
          onTap: () {
            final g = GlueProvider.generateOf(context);

            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return Downloads(
                  generateGlue: g.persistentZero,
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
          title: Text(AppLocalizations.of(context)!.blacklistedPage),
          onTap: () {
            final g = GlueProvider.generateOf(context);

            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlacklistedPage(
                    generateGlue: g.persistentZero,
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
    );
  }
}
