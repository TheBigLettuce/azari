// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

class AddToBookmarksButton extends StatelessWidget {
  final GridSkeletonState state;
  final bool Function() f;

  const AddToBookmarksButton({
    super.key,
    required this.state,
    required this.f,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          final proceed = f();
          if (!proceed) {
            return;
          }
          ScaffoldMessenger.of(state.scaffoldKey.currentContext!)
              .showSnackBar(SnackBar(
                  content: Text(
            AppLocalizations.of(context)!.bookmarked,
          )));
          state.gridKey.currentState?.selection.reset();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.bookmark_add));
  }
}
