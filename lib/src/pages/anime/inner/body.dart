// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class AnimeInnerBody extends StatefulWidget {
  final AnimeEntry entry;
  final AnimeAPI api;
  final EdgeInsets viewPadding;

  const AnimeInnerBody({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.api,
  });

  @override
  State<AnimeInnerBody> createState() => _AnimeInnerBodyState();
}

class _AnimeInnerBodyState extends State<AnimeInnerBody> {
  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      viewPadding: widget.viewPadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 4,
                children: widget.entry.genres
                    .map((e) => ActionChip(
                          surfaceTintColor:
                              Theme.of(context).colorScheme.surfaceTint,
                          elevation: 4,
                          labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8)),
                          visualDensity: VisualDensity.compact,
                          label: Text(e.title),
                          onPressed: e.unpressable
                              ? null
                              : () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) {
                                      return SearchAnimePage(
                                        api: widget.api,
                                        initalGenreId: e.id,
                                      );
                                    },
                                  ));
                                },
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ))
                    .toList(),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            _SegmentConstrained(
              api: widget.api,
              entry: widget.entry,
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
            ),
            AnimeCharactersWidget(api: widget.api, entry: widget.entry),
            AnimeRelations(entry: widget.entry, api: widget.api)
          ],
        ),
      ),
    );
  }
}
