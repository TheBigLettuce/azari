// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/image_view/app_bar/end_drawer_heading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImageViewEndDrawer extends StatelessWidget {
  final ScrollController scrollController;
  final Widget sliver;

  const ImageViewEndDrawer({
    super.key,
    required this.scrollController,
    required this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);

    return Drawer(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          EndDrawerHeading(AppLocalizations.of(context)!.infoHeadline),
          SliverPadding(
            padding: EdgeInsets.only(
                bottom:
                    insets.bottom + MediaQuery.of(context).viewPadding.bottom),
            sliver: sliver,
          )
        ],
      ),
    );
  }
}
