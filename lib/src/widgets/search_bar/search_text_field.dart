// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/notifiers/focus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../db/tags/post_tags.dart';
import '../notifiers/filter.dart';
import '../notifiers/tag_refresh.dart';

class SearchTextField extends StatelessWidget {
  final FilterNotifierData data;
  final String filename;
  final bool showDeleteButton;

  const SearchTextField(
    this.data,
    this.filename,
    this.showDeleteButton, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SearchBar(
          focusNode: data.searchFocus,
          leading: FocusNotifier.of(context).hasFocus
              ? BackButton(
                  onPressed: () {
                    data.searchController.clear();
                    FocusNotifier.of(context).unfocus();
                  },
                )
              : const Icon(Icons.search),
          trailing: showDeleteButton
              ? [
                  IconButton(
                      onPressed: () {
                        final notifier = TagRefreshNotifier.maybeOf(context);
                        PostTags.g.deletePostTags(filename);
                        notifier?.call();
                      },
                      icon: const Icon(Icons.delete))
                ]
              : null,
          hintText: AppLocalizations.of(context)!.filterHint,
          backgroundColor: MaterialStatePropertyAll(
              Theme.of(context).colorScheme.surface.withOpacity(0.1)),
          elevation: const MaterialStatePropertyAll(0),
          controller: data.searchController,
          onSubmitted: (value) {
            FocusNotifier.of(context).unfocus();
          }),
    );
  }
}
