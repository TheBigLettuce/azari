// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/net/booru/booru.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:flutter/material.dart";

class LoadTags extends StatefulWidget {
  const LoadTags({
    super.key,
    required this.res,
    required this.filename,
  });

  final String filename;

  final (int, Booru) res;

  @override
  State<LoadTags> createState() => _LoadTagsState();
}

class _LoadTagsState extends State<LoadTags> {
  bool isConforming = false;

  @override
  void initState() {
    super.initState();

    isConforming = ParsedFilenameResult.fromFilename(widget.filename).hasValue;
  }

  Future<void> _load() async {
    final localTags = LocalTagsService.safe();
    if (localTags == null) {
      return Future.value();
    }

    try {
      final tags = await localTags.loadFromDissassemble(
        widget.filename,
        widget.res,
      );

      localTags.addTagsPost(
        widget.filename,
        tags,
        true,
      );

      GalleryApi.safe()?.notify(null);
    } catch (e, stackTrace) {
      AlertService.safe()?.add(
        AlertData(
          e.toString(),
          stackTrace.toString(),
          (
            () {
              const TasksService().add<LoadTags>(_load);
            },
            const Icon(Icons.restart_alt_rounded)
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n();

    final task = const TasksService().status<LoadTags>(context);

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
          FilledButton(
            onPressed: task == TaskStatus.waiting ||
                    !LocalTagsService.available ||
                    !isConforming
                ? null
                : () => const TasksService().add<LoadTags>(_load),
            child: task == TaskStatus.waiting
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Text(l10n.fromBooru(widget.res.$2.string)),
          ),
        ],
      ),
    );
  }
}
