// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "search_anime.dart";

class _FilteringGenres extends StatefulWidget {
  final Future<Map<int, AnimeGenre>> future;
  final int? currentGenre;
  final void Function(int?) setGenre;

  const _FilteringGenres({
    required this.future,
    required this.currentGenre,
    required this.setGenre,
  });

  @override
  State<_FilteringGenres> createState() => __FilteringGenresState();
}

class __FilteringGenresState extends State<_FilteringGenres> {
  List<AnimeGenre>? _result;

  Widget _tile(AnimeGenre e) => ListTile(
        titleTextStyle:
            TextStyle(color: Theme.of(context).colorScheme.onSurface),
        title: Text(
          e.title,
          style: TextStyle(color: e.explicit ? Colors.red : null),
        ),
        selected: e.id == widget.currentGenre,
        onTap: () {
          widget.setGenre(e.id);

          Navigator.pop(context);
        },
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FutureBuilder(
        future: widget.future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(children: [
              TextButton(
                onPressed: () {
                  widget.setGenre(null);

                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)!.reset),
              ),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.filterHint),
                onChanged: (value) {
                  _result = snapshot.data!.values
                      .where((element) => element.title
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList();

                  setState(() {});
                },
              ),
              if (widget.currentGenre != null)
                _tile(snapshot.data![widget.currentGenre!]!),
              if (_result != null)
                if (_result == null)
                  const SizedBox.shrink()
                else
                  ..._result!
                      .where((element) => element.id != widget.currentGenre)
                      .map((e) => _tile(e))
              else
                ...snapshot.data!.values
                    .where((element) => element.id != widget.currentGenre)
                    .map((e) => _tile(e)),
            ]).animate().fadeIn();
          } else {
            return const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
        },
      ),
    );
  }
}
