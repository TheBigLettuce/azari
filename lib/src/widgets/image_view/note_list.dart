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
import 'package:gallery/src/pages/image_view.dart';

import '../../db/schemas/note.dart';
import '../../interfaces/cell.dart';
import 'notes_container.dart';

import 'package:gallery/src/widgets/notifiers/current_cell.dart';
import 'package:palette_generator/palette_generator.dart';

part 'notes_mixin.dart';

class NoteList<T extends Cell> extends StatefulWidget {
  final NoteInterface<T> noteInterface;
  final void Function()? onEmptyNotes;
  final Color backgroundColor;

  const NoteList(
      {super.key,
      required this.noteInterface,
      required this.onEmptyNotes,
      required this.backgroundColor});

  @override
  State<NoteList<T>> createState() => NoteListState<T>();
}

class NoteListState<T extends Cell> extends State<NoteList<T>>
    with _ImageViewNotesMixin<T> {
  @override
  void dispose() {
    disposeNotes();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = math.Random(96879873);

    return PopScope(
        canPop: !_extendNotes,
        onPopInvoked: (_) => unextendNotes(),
        child: notes == null || noteKeys == null
            ? const SizedBox.shrink()
            : NotesContainer(
                expandNotes: onExpandNotes,
                extendedNotes: _extendNotes,
                backgroundColor: widget.backgroundColor
                    .withOpacity(_extendNotes ? 0.95 : 0.5),
                child: ReorderableListView(
                  clipBehavior: Clip.antiAlias,
                  buildDefaultDragHandles: false,
                  scrollController: notesScrollController,
                  onReorder: (from, to) => onNoteReorder(context, from, to),
                  proxyDecorator: (child, idx, animation) {
                    return Material(
                      type: MaterialType.transparency,
                      color: Colors.white,
                      child: child,
                    );
                  },
                  children: notes == null
                      ? const []
                      : [
                          ...notes!.text.indexed.map((e) {
                            return Dismissible(
                                key: ValueKey(
                                    noteKeys![e.$1].microsecondsSinceEpoch),
                                background: Container(
                                    color: Colors.red.harmonizeWith(
                                        Theme.of(context).colorScheme.primary)),
                                onDismissed: (direction) {
                                  onNoteDismissed(context, notes!, e.$1);
                                },
                                child: ListTile(
                                  trailing: _extendNotes
                                      ? ReorderableDragStartListener(
                                          index: e.$1,
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                          ),
                                        )
                                      : null,
                                  titleTextStyle: const TextStyle(
                                      fontFamily: "ZenKurenaido"),
                                  onTap: _extendNotes
                                      ? null
                                      : () {
                                          noteTextController.text = e.$2;

                                          Navigator.push(
                                              context,
                                              DialogRoute(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text("Note"),
                                                    content: TextFormField(
                                                      controller:
                                                          noteTextController,
                                                      maxLines: null,
                                                      decoration:
                                                          const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () {
                                                            onNoteReplace(
                                                                context,
                                                                notes!,
                                                                e.$1,
                                                                noteTextController
                                                                    .text);
                                                          },
                                                          child: Text("Save"))
                                                    ],
                                                  );
                                                },
                                              ));
                                        },
                                  title: _extendNotes
                                      ? _FormFieldSaveable(e.$2, random: random,
                                          save: (str) {
                                          onNoteSave(
                                              context, notes!, e.$1, str);
                                        })
                                      : Text(
                                          e.$2,
                                          maxLines: _extendNotes ? null : 1,
                                          style: TextStyle(
                                              overflow: _extendNotes
                                                  ? null
                                                  : TextOverflow.ellipsis),
                                        ),
                                ));
                          })
                        ],
                )));
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
