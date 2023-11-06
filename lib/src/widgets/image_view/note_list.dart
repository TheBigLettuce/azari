// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:math' as math;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/notifiers/notes_visibility.dart';

import '../../db/schemas/note.dart';

class NoteList<T extends NoteBase> extends StatelessWidget {
  final ScrollController controller;
  final T notes;
  final List<DateTime> noteKeys;
  final TextEditingController textController;
  final void Function(BuildContext context, int from, int to) onReorder;
  final void Function(BuildContext context, T notes, int idx, String newText)
      onReplace;
  final void Function(BuildContext context, T notes, int idx) onDismissed;
  final void Function(
      BuildContext context, T notes, int idx, String currentText) onSave;

  const NoteList(
      {super.key,
      required this.controller,
      required this.noteKeys,
      required this.notes,
      required this.onDismissed,
      required this.onReorder,
      required this.onReplace,
      required this.onSave,
      required this.textController});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(96879873);
    final extend = NotesVisibilityNotifier.of(context);

    return ReorderableListView(
      clipBehavior: Clip.antiAlias,
      buildDefaultDragHandles: false,
      scrollController: controller,
      onReorder: (from, to) => onReorder(context, from, to),
      proxyDecorator: (child, idx, animation) {
        return Material(
          type: MaterialType.transparency,
          color: Colors.white,
          child: child,
        );
      },
      children: [
        ...notes.text.indexed.map((e) {
          return Dismissible(
              key: ValueKey(noteKeys[e.$1].microsecondsSinceEpoch),
              background: Container(
                  color: Colors.red
                      .harmonizeWith(Theme.of(context).colorScheme.primary)),
              onDismissed: (direction) {
                onDismissed(context, notes, e.$1);
              },
              child: ListTile(
                trailing: extend
                    ? ReorderableDragStartListener(
                        index: e.$1,
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      )
                    : null,
                titleTextStyle: const TextStyle(fontFamily: "ZenKurenaido"),
                onTap: extend
                    ? null
                    : () {
                        textController.text = e.$2;

                        Navigator.push(
                            context,
                            DialogRoute(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text("Note"),
                                  content: TextFormField(
                                    controller: textController,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          onReplace(context, notes, e.$1,
                                              textController.text);
                                        },
                                        child: Text("Save"))
                                  ],
                                );
                              },
                            ));
                      },
                title: extend
                    ? _FormFieldSaveable(e.$2, random: random, save: (str) {
                        onSave(context, notes, e.$1, str);
                      })
                    : Text(
                        e.$2,
                        maxLines: extend ? null : 1,
                        style: TextStyle(
                            overflow: extend ? null : TextOverflow.ellipsis),
                      ),
              ));
        })
      ],
    );
  }
}

class _FormFieldSaveable extends StatefulWidget {
  final String text;
  final void Function(String s) save;
  final math.Random random;

  const _FormFieldSaveable(this.text,
      {required this.save, required this.random});

  @override
  State<_FormFieldSaveable> createState() => __FormFieldSaveableState();
}

class __FormFieldSaveableState extends State<_FormFieldSaveable> {
  late final controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    if (widget.text != controller.text) {
      widget.save(controller.text);
    }
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
        effects: const [FadeEffect(end: 1.0)],
        child: TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
              border: InputBorder.none,
              prefix: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Transform.rotate(
                      angle: widget.random.nextInt(80).toDouble(),
                      child: Text(
                        "✦",
                        style: TextStyle(
                            color: Theme.of(context).iconTheme.color,
                            fontSize: 16),
                      )))),
          style: TextStyle(
              color: Theme.of(context).listTileTheme.textColor,
              fontFamily: "ZenKurenaido"),
        ));
  }
}
