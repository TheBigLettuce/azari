// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/widgets/notifiers/filter.dart";
import "package:gallery/src/widgets/notifiers/focus.dart";

class SearchTextField extends StatelessWidget {
  const SearchTextField(
    this.filename, {
    super.key,
  });

  final String filename;

  @override
  Widget build(BuildContext context) {
    final notifData = FocusNotifier.of(context);
    final data = FilterNotifier.maybeOf(context);

    if (data == null) {
      return const SizedBox.shrink();
    }

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
            ).animate().fadeIn(),
        ],
        hintText: AppLocalizations.of(context)!.filterHint,
        elevation: const WidgetStatePropertyAll(0),
        controller: data.searchController,
        onSubmitted: (value) {
          FocusNotifier.of(context).unfocus();
        },
      ),
    );
  }
}
