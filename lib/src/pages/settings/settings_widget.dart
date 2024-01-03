// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/db/schemas/statistics/statistics_booru.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';

import '../../db/schemas/settings/settings.dart';
import '../../widgets/restart_widget.dart';
import '../../widgets/skeletons/skeleton_settings.dart';
import '../../widgets/skeletons/skeleton_state.dart';
import 'settings_list.dart';

part 'is_restart.dart';
part 'select_booru.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final skeletonState = SkeletonState();

  @override
  void dispose() {
    skeletonState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonSettings(
      AppLocalizations.of(context)!.settingsPageName,
      skeletonState,
      child: SettingsList(
        sliver: true,
        scaffoldKey: skeletonState.scaffoldKey,
      ),
    );
  }
}
