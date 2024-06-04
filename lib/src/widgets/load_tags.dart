// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/plugs/gallery.dart";
import "package:gallery/src/widgets/notifiers/tag_refresh.dart";

class LoadTags extends StatelessWidget {
  const LoadTags({
    super.key,
    required this.res,
    required this.filename,
  });
  final DisassembleResult res;
  final String filename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SliverPadding(
      padding: const EdgeInsets.all(4),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: Text(l10n.loadTags),
            ),
            FilledButton(
              onPressed: TagRefreshNotifier.isRefreshingOf(context) ?? false
                  ? null
                  : () {
                      try {
                        final setIsRefreshing =
                            TagRefreshNotifier.setIsRefreshingOf(context);
                        setIsRefreshing?.call(true);

                        final notifier = TagRefreshNotifier.maybeOf(context);

                        final postTags = PostTags.fromContext(context);

                        postTags
                            .loadFromDissassemble(filename, res)
                            .then((value) {
                          postTags.addTagsPost(filename, value, true);
                          notifier?.call();
                          chooseGalleryPlug().notify(null);
                        }).whenComplete(() => setIsRefreshing?.call(false));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.notValidFilename(e.toString())),
                          ),
                        );
                      }
                    },
              child: TagRefreshNotifier.isRefreshingOf(context) ?? false
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text("From ${res.booru.string}"),
            ),
          ],
        ),
      ),
    );
  }
}
