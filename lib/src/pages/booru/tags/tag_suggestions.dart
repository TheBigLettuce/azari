// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import "dart:async";

// import "package:azari/src/db/services/services.dart";
// import "package:azari/src/net/booru/safe_mode.dart";
// import "package:azari/src/pages/booru/booru_page.dart";
// import "package:azari/src/typedefs.dart";
// import "package:azari/src/widgets/menu_wrapper.dart";
// import "package:flutter/material.dart";
// import "package:flutter_animate/flutter_animate.dart";

// const slideFadeEffects = <Effect<dynamic>>[
//   SlideEffect(
//     curve: Easing.emphasizedDecelerate,
//     duration: Durations.medium4,
//     begin: Offset(0.2, 0),
//     end: Offset.zero,
//   ),
//   FadeEffect(
//     delay: Duration(milliseconds: 80),
//     curve: Easing.standard,
//     duration: Durations.medium4,
//     begin: 0,
//     end: 1,
//   ),
// ];

// class TagSuggestions extends StatefulWidget {
//   const TagSuggestions({
//     super.key,
//     required this.tagging,
//     required this.onPressed,
//     required this.settingsService,
//     this.redBackground = false,
//     this.leading,
//   });

//   final bool redBackground;

//   final BooruTagging tagging;
//   final Widget? leading;

//   final SettingsService settingsService;

//   final void Function(String tag, SafeMode? safeMode)? onPressed;

//   @override
//   State<TagSuggestions> createState() => _TagSuggestionsState();
// }

// class _TagSuggestionsState extends State<TagSuggestions> {
//   SettingsService get settingsService => widget.settingsService;

//   late final StreamSubscription<void> watcher;
//   late final List<TagData> _tags = widget.tagging.get(30);
//   int refreshes = 0;

//   @override
//   void initState() {
//     super.initState();

//     watcher = widget.tagging.watch((_) {
//       _tags.clear();
//       setState(() {});

//       _tags.addAll(widget.tagging.get(30));

//       setState(() {
//         refreshes += 1;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     watcher.cancel();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n();
//     final theme = Theme.of(context);

//     return Animate(
//       effects: slideFadeEffects,
//       child: _tags.isEmpty
//           ? Row(
//               children: [
//                 if (widget.leading != null)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 4),
//                     child: widget.leading,
//                   ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.label_off_rounded,
//                         size: 16,
//                         color:
//                             theme.colorScheme.onSurface.withValues(alpha: 0.6),
//                       ),
//                       const Padding(padding: EdgeInsets.only(right: 4)),
//                       Text(
//                         l10n.noBooruTags,
//                         style: theme.textTheme.titleSmall?.copyWith(
//                           color: theme.colorScheme.onSurface
//                               .withValues(alpha: 0.6),
//                         ),
//                       ),
//                       const Padding(padding: EdgeInsets.only(right: 4)),
//                     ],
//                   ),
//                 ),
//               ],
//             )
//           : SizedBox(
//               height: 38,
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (widget.leading != null)
//                     Padding(
//                       padding: const EdgeInsets.only(left: 4),
//                       child: widget.leading,
//                     ),
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.only(right: 12),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(25),
//                         child: ListView.builder(
//                           key: ValueKey(refreshes),
//                           itemCount: _tags.length,
//                           scrollDirection: Axis.horizontal,
//                           itemBuilder: (context, index) {
//                             return Padding(
//                               padding: const EdgeInsets.only(right: 4),
//                               child: SingleTagWidget(
//                                 tag: _tags[index],
//                                 tagging: widget.tagging,
//                                 onPressed: widget.onPressed,
//                                 redBackground: widget.redBackground,
//                                 settingsService: settingsService,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

// class SingleTagWidget extends StatelessWidget {
//   const SingleTagWidget({
//     super.key,
//     required this.tag,
//     required this.onPressed,
//     required this.tagging,
//     required this.redBackground,
//     required this.settingsService,
//   });

//   final bool redBackground;

//   final TagData tag;
//   final BooruTagging tagging;

//   final void Function(String tag, SafeMode? safeMode)? onPressed;

//   final SettingsService settingsService;

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n();

//     return MenuWrapper(
//       title: tag.tag,
//       items: [
//         if (onPressed != null)
//           launchGridSafeModeItem(
//             context,
//             tag.tag,
//             (context, _, [safeMode]) {
//               onPressed!(tag.tag, safeMode);
//             },
//             l10n,
//             settingsService: settingsService,
//           ),
//         PopupMenuItem(
//           onTap: () {
//             tagging.delete(tag.tag);
//           },
//           child: Text(l10n.delete),
//         ),
//       ],
//       child: FilledButton.tonalIcon(
//         icon: Icon(
//           Icons.tag_rounded,
//           color: redBackground ? Colors.black.withValues(alpha: 0.8) : null,
//         ),
//         style: ButtonStyle(
//           visualDensity: VisualDensity.comfortable,
//           backgroundColor: WidgetStatePropertyAll(
//             redBackground ? Colors.pink.shade300 : null,
//           ),
//         ),
//         onPressed: onPressed == null
//             ? null
//             : () {
//                 onPressed!(tag.tag, null);
//               },
//         label: Text(
//           tag.tag,
//           style: redBackground
//               ? TextStyle(color: Colors.black.withValues(alpha: 0.8))
//               : null,
//         ),
//       ),
//     );
//   }
// }
