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
  Future<void>? _status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RawChip(
        avatar: const Icon(Icons.wallpaper_rounded),
        onPressed: _status != null
            ? null
            : () {
                _status = PlatformApi.current()
                    .setWallpaper(widget.id)
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
