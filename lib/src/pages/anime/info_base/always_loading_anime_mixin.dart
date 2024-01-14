// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/settings/misc_settings.dart';
import 'package:gallery/src/interfaces/anime/anime_entry.dart';

mixin AlwaysLoadingAnimeMixin {
  final alwaysLoading = MiscSettings.current.animeAlwaysLoadFromNet;
  Future? loadingFuture;

  void maybeFetchInfo(AnimeEntry entry, void Function(AnimeEntry e) f) {
    if (alwaysLoading) {
      loadingFuture = entry.site.api.info(entry.id).then((value) {
        if (value == null) {
          return value;
        }

        f(value);

        return value;
      });
    }
  }

  Widget wrapLoading(BuildContext context, Widget child) => alwaysLoading
      ? FutureBuilder(
          future: loadingFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              return Container(
                color: Theme.of(context).colorScheme.background,
                child: child.animate().fadeIn(),
              );
            }
          },
        )
      : child;
}
