// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/widgets/search/autocomplete/autocomplete_tag.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
// class LaunchingSearchWidget extends StatefulWidget {
//   const LaunchingSearchWidget({
//     super.key,
//     required this.state,
//     required this.searchController,
//     required this.hint,
//   });

//   final SearchLaunchGridData state;
//   final SearchController searchController;
//   final String? hint;

//   @override
//   State<LaunchingSearchWidget> createState() => _LaunchingSearchWidgetState();
// }

// class _LaunchingSearchWidgetState extends State<LaunchingSearchWidget> {
//   SearchLaunchGridData get state => widget.state;
//   SearchController get searchController => widget.searchController;

//   (Future<List<BooruTag>>, String)? previousSearch;

//   final _ScrollHack _scrollHack = _ScrollHack();

//   @override
//   void dispose() {
//     _scrollHack.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;

//     final addItems = state.addItems(context);

//     return SearchAnchor(
//       builder: (context, controller) {
//         return Center(
//           child: IconButton.filledTonal(
//             onPressed: controller.openView,
//             visualDensity: VisualDensity.comfortable,
//             icon: const Icon(Icons.search_rounded),
//           ),
//         );
//       },
//       viewTrailing: [
//         ...addItems,
//         IconButton(
//           onPressed: searchController.clear,
//           icon: const Icon(Icons.close),
//         ),
//       ],
//       viewOnSubmitted: (value) {
//         state.onSubmit(context, value);
//       },
//       viewHintText: "${l10n.searchHint} ${widget.hint ?? ''}",
//       searchController: searchController,
//       suggestionsBuilder: (suggestionsContext, controller) {
//         if (controller.text.isEmpty) {
//           return [state.header];
//         }

//         if (previousSearch == null) {
//           previousSearch = (
// autocompleteTag(controller.text, state.completeTag),
//             controller.text
//           );
//         } else {
//           if (previousSearch!.$2 != controller.text) {
//             previousSearch?.$1.ignore();
//             previousSearch = (
//               autocompleteTag(controller.text, state.completeTag),
//               controller.text
//             );
//           }
//         }

//         return [
//           FutureBuilder(
//             key: ValueKey(previousSearch!.$2),
//             future: previousSearch!.$1,
//             builder: (context, snapshot) {
//               return !snapshot.hasData
//                   ? const Center(
//                       child: Padding(
//                         padding: EdgeInsets.only(top: 40),
//                         child: SizedBox(
//                           height: 4,
//                           width: 40,
//                           child: LinearProgressIndicator(),
//                         ),
//                       ),
//                     )
//                   : ListBody(
//                       children: snapshot.data!
//                           .map(
//                             (e) => ListTile(
//                               leading: const Icon(Icons.tag_outlined),
//                               title: Text(e.tag),
//                               onTap: () {
//                                 final tags = List<String>.from(
//                                   controller.text.split(" "),
//                                 );

//                                 if (tags.isNotEmpty) {
//                                   tags.removeLast();
//                                   tags.remove(e.tag);
//                                 }

//                                 tags.add(e.tag);

//                                 final tagsString = tags.reduce(
//                                   (value, element) => "$value $element",
//                                 );

//                                 searchController.text = "$tagsString ";
//                               },
//                               trailing: Text(e.count.toString()),
//                             ),
//                           )
//                           .toList(),
//                     );
//             },
//           ),
//         ];
//       },
//     );
//   }
// }

// class SearchLaunchGridData {
//   const SearchLaunchGridData({
//     required this.completeTag,
//     required this.searchText,
//     required this.addItems,
//     required this.header,
//     this.swapSearchIconWithAddItems = true,
//     required this.onSubmit,
//     this.searchTextAsLabel = false,
//   });

//   final List<Widget> Function(BuildContext) addItems;
//   final String searchText;
//   final void Function(BuildContext, String) onSubmit;
//   final bool swapSearchIconWithAddItems;
//   final Future<List<BooruTag>> Function(String tag) completeTag;
//   final Widget header;
//   final bool searchTextAsLabel;
// }

// class _ScrollHack extends ScrollController {
//   @override
//   bool get hasClients => false;
// }
