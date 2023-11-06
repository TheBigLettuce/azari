// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/widgets/notifiers/app_bar_visibility.dart';

class NotesContainer extends StatelessWidget {
  final void Function() expandNotes;
  final Widget child;
  final Color backgroundColor;
  final bool extendedNotes;

  const NotesContainer(
      {super.key,
      required this.expandNotes,
      required this.backgroundColor,
      required this.extendedNotes,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: const [
        FadeEffect(begin: 1, end: 0, duration: Duration(milliseconds: 500))
      ],
      autoPlay: false,
      target: AppBarVisibilityNotifier.of(context) ? 0 : 1,
      child: IgnorePointer(
        ignoring: !AppBarVisibilityNotifier.of(context),
        child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                bottom: MediaQuery.of(context).padding.bottom + 4,
                right: 4,
                left: 4),
            child: Align(
              alignment: Alignment.topRight,
              child: AnimatedContainer(
                curve: Curves.easeInOutCirc,
                duration: const Duration(milliseconds: 180),
                height: extendedNotes
                    ? MediaQuery.of(context).size.height -
                        MediaQuery.viewPaddingOf(context).bottom -
                        MediaQuery.viewPaddingOf(context).top -
                        (kToolbarHeight + 80 + 8 + 4)
                    : 120,
                width: extendedNotes ? MediaQuery.of(context).size.width : 100,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.all(Radius.elliptical(10, 10)),
                  color: backgroundColor,
                ),
                child: ClipPath(
                    child: Column(
                  crossAxisAlignment: extendedNotes
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: expandNotes,
                        icon: Icon(extendedNotes
                            ? Icons.arrow_back
                            : Icons.sticky_note_2_outlined)),
                    Expanded(child: child)
                  ],
                )),
              ),
            )),
      ),
    );
  }
}
