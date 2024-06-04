// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/widgets/gesture_dead_zones.dart";
import "package:gallery/src/widgets/image_view/app_bar/end_drawer_heading.dart";

class ImageViewEndDrawer extends StatelessWidget {
  const ImageViewEndDrawer({
    super.key,
    required this.scrollController,
    required this.sliver,
  });
  final ScrollController scrollController;
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);

    return Drawer(
      child: GestureDeadZones(
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            EndDrawerHeading(AppLocalizations.of(context)!.infoHeadline),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom:
                    insets.bottom + MediaQuery.of(context).viewPadding.bottom,
              ),
              sliver: sliver,
            ),
          ],
        ),
      ),
    );
  }
}
