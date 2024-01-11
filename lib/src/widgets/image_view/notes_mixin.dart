// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'note_list.dart';

mixin _ImageViewNotesMixin<T extends Cell> on State<NoteList<T>> {
  NoteBase? notes;
  List<DateTime>? noteKeys;

  bool _extendNotes = false;

  final noteTextController = TextEditingController();
  final notesScrollController = ScrollController();

  void disposeNotes() {
    noteTextController.dispose();
    notesScrollController.dispose();
  }

  void toggle() {
    setState(() {
      _extendNotes = !_extendNotes;
    });
  }

  void unextendNotes() {
    if (_extendNotes) {
      setState(() {
        _extendNotes = false;
      });
    }
  }

  void addNote(T currentCell, PaletteGenerator? currentPalette) {
    noteTextController.text = "";

    if (_extendNotes) {
      final c = currentPalette?.dominantColor;
      widget.noteInterface
          .addNote("New note", currentCell, c?.color, c?.bodyTextColor);

      loadNotes(currentCell, addNote: true);
      setState(() {});
      notesScrollController.animateTo(
          notesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Easing.emphasizedAccelerate);
      return;
    }

    noteTextController.text = "New note";

    Navigator.push(
        context,
        DialogRoute(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("New note"), // TODO: change
              content: TextFormField(
                autofocus: true,
                controller: noteTextController,
                maxLines: null,
                minLines: 4,
                autovalidateMode: AutovalidateMode.always,
                validator: (value) {
                  if ((value?.isEmpty ?? true)) {
                    return "Value is empty";
                  }

                  return null;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final c = currentPalette?.dominantColor;

                    widget.noteInterface.addNote(noteTextController.text,
                        currentCell, c?.color, c?.bodyTextColor);
                    loadNotes(currentCell);
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text("Add"), // TODO: change
                )
              ],
            );
          },
        ));
  }

  void loadNotes(T currentCell,
      {int? replaceIndx,
      bool addNote = false,
      int? removeNote,
      (int from, int to)? reorder}) {
    notes = widget.noteInterface.load(currentCell);

    if (notes == null || notes!.text.isEmpty) {
      if (widget.onEmptyNotes != null) {
        widget.onEmptyNotes!();
      } else {
        try {
          setState(() {
            _extendNotes = false;
          });
        } catch (_) {}
      }

      return;
    }

    if (replaceIndx != null) {
      noteKeys![replaceIndx] = DateTime.now();
      return;
    } else if (addNote) {
      noteKeys!.add(DateTime.now());
      return;
    } else if (removeNote != null) {
      noteKeys!.removeAt(removeNote);
      return;
    } else if (reorder != null) {
      final (from, to) = reorder;
      if (from == to) {
        return;
      }

      final e1 = noteKeys![from];
      noteKeys!.removeAt(from);
      if (to == 0) {
        noteKeys!.insert(0, e1);
      } else {
        noteKeys!.insert(to - 1, e1);
      }

      return;
    }

    DateTime? previousTime;
    noteKeys = notes!.text.map((_) {
      if (previousTime == null) {
        previousTime = DateTime.now();
        return previousTime!;
      } else {
        var now = DateTime.now();
        while (now.microsecondsSinceEpoch ==
            previousTime!.microsecondsSinceEpoch) {
          now = DateTime.now();
        }

        previousTime = now;
        return now;
      }
    }).toList();
  }

  void onExpandNotes() {
    _extendNotes = !_extendNotes;
    setState(() {});
  }

  void onNoteDismissed(BuildContext context, NoteBase notes, int idx) {
    final currentCell = CurrentCellNotifier.of<T>(context);

    final d = notes.text[idx];
    final c = currentCell;
    widget.noteInterface.delete(currentCell, idx);

    loadNotes(currentCell, removeNote: idx);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Note deleted"), // TODO: change
      action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            widget.noteInterface.addNote(
                d,
                c,
                notes.backgroundColor == null
                    ? null
                    : Color(notes.backgroundColor!),
                notes.textColor == null ? null : Color(notes.textColor!));

            loadNotes(currentCell, addNote: true);
            try {
              setState(() {});
            } catch (_) {}
          }),
    ));
  }

  void onNoteReorder(BuildContext context, int from, int to) {
    final currentCell = CurrentCellNotifier.of<T>(context);

    widget.noteInterface.reorder(currentCell, from, to);
    loadNotes(currentCell, reorder: (from, to));
    setState(() {});
  }

  void onNoteReplace(
      BuildContext context, NoteBase notes, int idx, String newText) {
    final currentCell = CurrentCellNotifier.of<T>(context);

    widget.noteInterface.replace(currentCell, idx, newText);
    loadNotes(currentCell, replaceIndx: idx);

    setState(() {});
    Navigator.pop(context);
  }

  void onNoteSave(
      BuildContext context, NoteBase notes, int idx, String currentText) {
    if (currentText.isEmpty) {
      return;
    }

    final currentCell = CurrentCellNotifier.of<T>(context);

    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      widget.noteInterface.replace(currentCell, idx, currentText);
      loadNotes(currentCell, replaceIndx: idx);
      try {
        setState(() {});
      } catch (_) {}
    });
  }
}
