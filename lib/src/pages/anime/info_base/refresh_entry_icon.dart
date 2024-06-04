// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/interfaces/anime/anime_api.dart";
import "package:gallery/src/interfaces/anime/anime_entry.dart";

class RefreshEntryIcon extends StatefulWidget {
  const RefreshEntryIcon(
    this.entry,
    this.save, {
    super.key,
    required this.api,
  });
  final AnimeEntryData entry;
  final AnimeAPI api;
  final void Function(AnimeEntryData) save;

  @override
  State<RefreshEntryIcon> createState() => _RefreshEntryIconState();
}

class _RefreshEntryIconState extends State<RefreshEntryIcon> {
  Future<void>? _refreshingProgress;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _refreshingProgress != null
          ? null
          : () {
              _refreshingProgress = widget.api.info(widget.entry.id)
                ..then((value) {
                  widget.save(value);
                }).whenComplete(() {
                  _refreshingProgress = null;

                  try {
                    setState(() {});
                  } catch (_) {}
                });

              setState(() {});
            },
      icon: const Icon(Icons.refresh_rounded),
    );
  }
}
