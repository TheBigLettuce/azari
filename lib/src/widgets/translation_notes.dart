// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/booru/booru.dart";

import "package:gallery/src/interfaces/booru/booru_api.dart";

class TranslationNotes extends StatefulWidget {
  const TranslationNotes({
    super.key,
    required this.booru,
    required this.postId,
  });
  final int postId;
  final Booru booru;

  static Widget tile(BuildContext context, int postId, Booru booru) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.hasTranslations),
      subtitle: Text(AppLocalizations.of(context)!.tapToView),
      onTap: () {
        Navigator.push(
          context,
          DialogRoute<void>(
            context: context,
            builder: (context) {
              return TranslationNotes(
                postId: postId,
                booru: booru,
              );
            },
          ),
        );
      },
    );
  }

  @override
  State<TranslationNotes> createState() => _TranslationNotesState();
}

class _TranslationNotesState extends State<TranslationNotes> {
  late final Dio dio;
  late Future<Iterable<String>> f;

  @override
  void initState() {
    super.initState();

    dio = BooruAPI.defaultClientForBooru(widget.booru);
    f = BooruAPI.fromEnum(widget.booru, dio, EmptyPageSaver())
        .notes(widget.postId);
  }

  @override
  void dispose() {
    dio.close(force: true);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translationTitle),
      content: FutureBuilder(
        future: f,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!
                    .map(
                      (e) => ListTile(
                        title: Text(e),
                      ),
                    )
                    .toList(),
              ),
            );
          }

          return SizedBox.fromSize(
            size: const Size.square(42),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
