// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../notifiers/tag_manager.dart';

class SearchLaunchGrid1 extends StatefulWidget {
  final Booru booru;
  final Future<List<String>> Function(String) complF;
  final String? hint;

  const SearchLaunchGrid1(
      {super.key, required this.booru, required this.complF, this.hint});

  @override
  State<SearchLaunchGrid1> createState() => _SearchLaunchGrid1State();
}

class _SearchLaunchGrid1State extends State<SearchLaunchGrid1> {
  final controller = TextEditingController();
  final focus = FocusNode();
  String? currentlyHighlightedTag;

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutocompleteWidget(
        controller,
        (s) {
          currentlyHighlightedTag = s;
        },
        (s) => TagManagerNotifier.ofUnrestorable(context)
            .onTagPressed(context, s, widget.booru, false),
        () {
          // => _state.mainFocus.requestFocus(),
        },
        widget.complF,
        focus,
        // ignoreFocusNotifier: true,
        scrollHack: _ScrollHack(),
        customHint:
            "${AppLocalizations.of(context)!.searchHint} ${widget.hint?.toLowerCase() ?? ''}");
  }
}

// class SearchLaunchGrid extends StatelessWidget {
//   final Booru booru;

//   const SearchLaunchGrid({super.key, required this.booru});

//   @override
//   Widget build(BuildContext context) {
//     return AutocompleteWidget(searchTextController, (s) {
//       currentlyHighlightedTag = s;
//     },
//         (s) => TagManagerNotifier.of(context)
//             .onTagPressed(context, s, booru, _state.restorable),
//         () => _state.mainFocus.requestFocus(),
//         BooruAPINotifier.of(context).completeTag,
//         searchFocus,
//         scrollHack: _scrollHack,
//         showSearch: !Platform.isAndroid,
//         roundBorders: false,
//         ignoreFocusNotifier: Platform.isAndroid,
//         addItems: _state.addItems,
//         customHint:
//             "${AppLocalizations.of(context)!.searchHint} ${hint?.toLowerCase() ?? ''}");
//   }
// }

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
