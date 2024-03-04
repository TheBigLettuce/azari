// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

import '../../notifiers/focus.dart';

InputDecoration autocompleteBarDecoration(
    BuildContext context, void Function() iconOnPressed, List<Widget>? addItems,
    {required bool showSearch,
    int? searchCount,
    required bool roundBorders,
    required String hint}) {
  return InputDecoration(
    prefixIcon: FocusNotifier.of(context).hasFocus
        ? IconButton(
            onPressed: FocusNotifier.of(context).unfocus,
            icon: Badge.count(
              count: searchCount ?? 0,
              isLabelVisible: searchCount != null,
              child: const Icon(Icons.arrow_back),
            ),
            padding: EdgeInsets.zero,
          )
        : showSearch
            ? IconButton(
                onPressed: null,
                icon: Badge.count(
                  count: searchCount ?? 0,
                  isLabelVisible: searchCount != null,
                  // child: const Icon(Icons.search_rounded),
                ),
                padding: EdgeInsets.zero,
              )
            : null,
    suffixIcon: addItems == null || addItems.isEmpty
        ? null
        : Wrap(
            children: addItems,
          ),
    suffix: IconButton(
      onPressed: iconOnPressed,
      icon: const Icon(Icons.close),
    ),
    hintText: hint,
    // fillColor: Colors.black,
    border: roundBorders
        ? const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)))
        : InputBorder.none,
    isDense: false,
  );
}
