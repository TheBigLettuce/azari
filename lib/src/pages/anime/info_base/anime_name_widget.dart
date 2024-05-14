// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";

class AnimeNameWidget extends StatelessWidget {
  const AnimeNameWidget({
    super.key,
    required this.title,
    required this.titleEnglish,
    required this.titleJapanese,
    required this.titleSynonyms,
    required this.safeMode,
  });
  final String title;
  final String titleEnglish;
  final String titleJapanese;
  final List<String> titleSynonyms;
  final AnimeSafeMode safeMode;

  @override
  Widget build(BuildContext context) {
    Widget title() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuWrapper(
              title: this.title,
              child: Text(
                this.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: safeMode == AnimeSafeMode.h ||
                              safeMode == AnimeSafeMode.ecchi
                          ? Colors.pink.withOpacity(0.8)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                    ),
              ),
            ),
            Text(
              "$titleEnglish / $titleJapanese",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
            ),
          ],
        );

    return Align(
      alignment: Alignment.topLeft,
      child: titleSynonyms.isEmpty
          ? title()
          : Tooltip(
              textStyle:
                  safeMode == AnimeSafeMode.h || safeMode == AnimeSafeMode.ecchi
                      ? TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.8),
                        )
                      : null,
              decoration: safeMode == AnimeSafeMode.h ||
                      safeMode == AnimeSafeMode.ecchi
                  ? BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.8),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    )
                  : null,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: 2.seconds,
              message: AppLocalizations.of(context)!
                  .alsoKnownAs(titleSynonyms.join("\n")),
              child: title(),
            ),
    );
  }
}
