// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/init_main/restart_widget.dart";
import "package:azari/src/db/services/local_tags_helper.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/typedefs.dart";
import "package:flutter/material.dart";

extension LoadTagsGlobalNotifier on GlobalProgressTab {
  ValueNotifier<Future<void>?> loadTags() {
    return get("LoadTags", () => ValueNotifier<Future<void>?>(null));
  }
}

class LoadTags extends StatelessWidget {
  const LoadTags({
    super.key,
    required this.res,
    required this.filename,
    required this.localTags,
    required this.galleryService,
  });

  final String filename;

  final ParsedFilenameResult res;

  final GalleryService? galleryService;
  final LocalTagsService? localTags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    final notifier = GlobalProgressTab.maybeOf(context)?.loadTags();

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: Text(l10n.loadTags),
          ),
          if (notifier != null)
            ListenableBuilder(
              listenable: notifier,
              builder: (context, _) {
                return FilledButton(
                  onPressed: notifier.value != null || localTags == null
                      ? null
                      : () {
                          notifier.value = Future(() async {
                            final tags = await localTags!.loadFromDissassemble(
                              filename,
                              res,
                            );

                            localTags!.addTagsPost(
                              filename,
                              tags,
                              true,
                            );

                            galleryService?.notify(null);
                          }).onError((e, _) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.notValidFilename(e.toString()),
                                  ),
                                ),
                              );
                            }

                            return null;
                          }).whenComplete(() => notifier.value = null);
                        },
                  child: notifier.value != null
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            year2023: false,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Text(l10n.fromBooru(res.booru.string)),
                );
              },
            )
          else
            FilledButton(
              onPressed: null,
              child: Text(l10n.fromBooru(res.booru.string)),
            ),
        ],
      ),
    );
  }
}
