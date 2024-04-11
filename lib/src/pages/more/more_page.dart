// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/main.dart';
import 'package:gallery/src/pages/more/downloads.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';

import 'dashboard/dashboard.dart';
import 'blacklisted_page.dart';
import 'settings/settings_widget.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 12,
            top: 12 + 40 + MediaQuery.viewPaddingOf(context).top,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                icon: const Icon(Icons.dashboard_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return const Dashboard();
                    },
                  ));
                },
              ),
              const Padding(padding: EdgeInsets.only(left: 8)),
              IconButton.filled(
                icon: const Icon(Icons.download_outlined),
                onPressed: () {
                  final g = GlueProvider.generateOf(context);

                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return Downloads(
                        generateGlue: g,
                      );
                    },
                  ));
                },
              ),
              const Padding(padding: EdgeInsets.only(left: 8)),
              IconButton.filled(
                icon: const Icon(Icons.hide_image_outlined),
                onPressed: () {
                  final g = GlueProvider.generateOf(context);

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlacklistedPage(
                          generateGlue: g,
                        ),
                      ));
                },
              ),
              const Padding(padding: EdgeInsets.only(left: 8)),
              IconButton.filled(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(
                    builder: (context) {
                      return const SettingsWidget();
                    },
                  ));
                },
              ),
            ],
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: 0.4363323,
                child: Icon(
                  const IconData(0x963F),
                  size: 78,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  applyTextScaling: true,
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 12)),
              Text(
                azariVersion,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
