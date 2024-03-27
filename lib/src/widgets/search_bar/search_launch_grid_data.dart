// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class SearchLaunchGridData {
  final FocusNode mainFocus;
  final List<Widget> Function(BuildContext) addItems;
  final String searchText;
  final void Function(BuildContext, String) onSubmit;
  final bool swapSearchIconWithAddItems;
  final Future<List<String>> Function(String tag) completeTag;

  final bool disabled;
  final Widget header;
  final bool searchTextAsLabel;

  const SearchLaunchGridData({
    required this.mainFocus,
    required this.completeTag,
    required this.searchText,
    required this.addItems,
    required this.header,
    this.swapSearchIconWithAddItems = true,
    this.disabled = false,
    required this.onSubmit,
    this.searchTextAsLabel = false,
  });
}
