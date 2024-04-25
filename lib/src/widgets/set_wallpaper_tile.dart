// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/interfaces/logging/logging.dart";
import "package:gallery/src/plugs/platform_functions.dart";

class SetWallpaperTile extends StatefulWidget {
  const SetWallpaperTile({
    super.key,
    required this.id,
  });

  final int id;

  @override
  State<SetWallpaperTile> createState() => _SetWallpaperTileState();
}

class _SetWallpaperTileState extends State<SetWallpaperTile> {
  Future? _status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RawChip(
        avatar: const Icon(Icons.wallpaper_rounded),
        onPressed: _status != null
            ? null
            : () {
                _status = PlatformFunctions.setWallpaper(widget.id)
                    .onError((error, stackTrace) {
                  LogTarget.unknown.logDefaultImportant(
                    "setWallpaper".errorMessage(error),
                    stackTrace,
                  );
                }).whenComplete(() {
                  _status = null;

                  setState(() {});
                });

                setState(() {});
              },
        label: _status != null
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(AppLocalizations.of(context)!.setAsWallpaper),
      ),
    );
  }
}

// class _WallpaperTargetDialog extends StatefulWidget {
//   final int id;
//   final void Function(Future) setProgress;

//   const _WallpaperTargetDialog({
//     super.key,
//     required this.setProgress,
//     required this.id,
//   });

//   @override
//   State<_WallpaperTargetDialog> createState() => __WallpaperTargetDialogState();
// }

// class __WallpaperTargetDialogState extends State<_WallpaperTargetDialog> {
//   bool asHome = true;
//   bool asLockscreen = false;

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CheckboxListTile(
//               title: const Text("As Home"), // TODO: change
//               value: asHome,
//               onChanged: (value) {
//                 if (value == null) {
//                   return;
//                 }

//                 asHome = value;

//                 setState(() {});
//               }),
//           CheckboxListTile(
//               title: const Text("As Lockscreen"), // TODO: change
//               value: asLockscreen,
//               onChanged: (value) {
//                 if (value == null) {
//                   return;
//                 }

//                 asLockscreen = value;

//                 setState(() {});
//               })
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           child: Text(
//             AppLocalizations.of(context)!.back,
//           ),
//         ),
//         TextButton(
//           onPressed: asHome == false && asLockscreen == false
//               ? null
//               : () {
//                   widget.setProgress(;

//                   Navigator.pop(context);
//                 },
//           child: Text(
//             AppLocalizations.of(context)!.ok,
//           ),
//         ),
//       ],
//     );
//   }
// }
