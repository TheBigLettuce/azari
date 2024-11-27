// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/init_main/restart_widget.dart";
import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/pages/more/settings/settings_list.dart";
import "package:azari/src/widgets/skeletons/settings.dart";
import "package:azari/src/widgets/skeletons/skeleton_state.dart";
import "package:flutter/material.dart";

part "is_restart.dart";
part "select_booru.dart";
part "select_theme.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final skeletonState = SkeletonState();

  @override
  void dispose() {
    skeletonState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSkeleton(
      AppLocalizations.of(context)!.settingsPageName,
      skeletonState,
      child: SliverPadding(
        padding: const EdgeInsets.only(bottom: 8) +
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        sliver: SettingsList(
          sliver: true,
          db: DatabaseConnectionNotifier.of(context),
        ),
      ),
    );
  }
}
