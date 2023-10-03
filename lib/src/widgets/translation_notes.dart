// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../interfaces/booru.dart';

class TranslationNotes extends StatefulWidget {
  final int postId;
  final BooruAPI api;

  static Widget tile(BuildContext context, Color foregroundColor, int postId,
      BooruAPI Function() api) {
    return ListTile(
      textColor: foregroundColor,
      title: Text("Has translations"),
      subtitle: Text("Tap to view"),
      onTap: () {
        Navigator.push(
            context,
            DialogRoute(
              context: context,
              builder: (context) {
                return TranslationNotes(
                  postId: postId,
                  api: api(),
                );
              },
            ));
      },
    );
  }

  const TranslationNotes({super.key, required this.api, required this.postId});

  @override
  State<TranslationNotes> createState() => _TranslationNotesState();
}

class _TranslationNotesState extends State<TranslationNotes> {
  late final future = widget.api.notes(widget.postId);

  @override
  void dispose() {
    widget.api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Translation"),
      content: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: snapshot.data!
                      .map((e) => ListTile(
                            title: Text(e),
                          ))
                      .toList(),
                ),
              );
            }

            return SizedBox.fromSize(
              size: const Size.square(42),
              child: const Center(child: CircularProgressIndicator()),
            );
          }),
    );
  }
}
