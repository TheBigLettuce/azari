// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime.dart';

class TabBarWrapper extends StatefulWidget {
  final TextEditingController controller;
  final TabBar tabBar;
  final void Function(String? value) filter;
  final bool Function(bool forceSearchPage) onPressed;

  const TabBarWrapper({
    required super.key,
    required this.tabBar,
    required this.controller,
    required this.filter,
    required this.onPressed,
  });

  @override
  State<TabBarWrapper> createState() => _TabBarWrapperState();
}

class _TabBarWrapperState extends State<TabBarWrapper> {
  bool _showSearchField = false;

  bool clearOrHide() {
    if (widget.controller.text.isNotEmpty) {
      widget.controller.clear();
      widget.filter("");

      setState(() {});

      return false;
    } else {
      hide();

      return true;
    }
  }

  void hideAndClear() {
    widget.controller.clear();

    hide();
  }

  void hide() {
    _showSearchField = false;

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rightPadding = MediaQuery.systemGestureInsetsOf(context).right;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Animate(
            target: _showSearchField ? 1 : 0,
            effects: [
              const FadeEffect(begin: 1, end: 0),
              SwapEffect(
                builder: (_, __) {
                  return Stack(
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                                left: (rightPadding <= 0
                                    ? 44
                                    : 44 + (rightPadding / 2)),
                                right: 44 + 8),
                            hintText: AppLocalizations.of(context)!.filterHint,
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: Theme.of(context)
                                  .tabBarTheme
                                  .labelStyle
                                  ?.fontSize,
                            )),
                        controller: widget.controller,
                        onChanged: widget.filter,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 4),
                        child: SizedBox(
                            width:
                                24 + (rightPadding <= 0 ? 8 : rightPadding / 2),
                            child: GestureDetector(
                              onTap: () {
                                widget.controller.text = "";
                                widget.filter("");
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.8),
                              ),
                            )),
                      )
                    ],
                  );
                },
              )
            ],
            child: widget.tabBar,
          ),
          Container(
            height: 44,
            width: rightPadding <= 0 ? 44 : 44 + (rightPadding / 2),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.background.withOpacity(0.7),
                  Theme.of(context).colorScheme.background.withOpacity(0.5),
                  Theme.of(context).colorScheme.background.withOpacity(0.3),
                  Theme.of(context).colorScheme.background.withOpacity(0)
                ])),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
                width: 24 + 24 + (rightPadding <= 0 ? 8 : rightPadding / 2),
                child: GestureDetector(
                  onTap: () {
                    if (!widget.onPressed(false)) {
                      _showSearchField = !_showSearchField;
                      widget.filter(null);

                      setState(() {});
                    }
                  },
                  child: Icon(
                    Icons.search,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceTint
                        .withOpacity(0.8),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
