// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../notifiers/filter.dart';

class SearchTextField extends StatelessWidget {
  final FilterNotifierData data;
  final String filename;

  const SearchTextField(
    this.data,
    this.filename, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final notifData = FocusNotifier.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: SearchBar(
          focusNode: data.searchFocus,
          leading: notifData.hasFocus
              ? BackButton(
                  onPressed: notifData.unfocus,
                )
              : const Icon(Icons.search),
          trailing: [
            if (notifData.hasFocus)
              IconButton(
                onPressed: data.searchController.clear,
                icon: const Icon(Icons.close_rounded),
              ).animate().fadeIn()
          ],
          hintText: AppLocalizations.of(context)!.filterHint,
          elevation: const MaterialStatePropertyAll(0),
          controller: data.searchController,
          onSubmitted: (value) {
            FocusNotifier.of(context).unfocus();
          }),
    );
  }
}
