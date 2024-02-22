// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/net/manga/manga_dex.dart';
import 'package:gallery/src/pages/anime/anime.dart';
import 'package:gallery/src/widgets/grid/segment_label.dart';

class MangaPage extends StatefulWidget {
  final void Function(bool) procPop;
  final EdgeInsets viewPadding;

  const MangaPage({
    super.key,
    required this.procPop,
    required this.viewPadding,
  });

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  final dio = Dio();
  late final api = MangaDex(dio);

  @override
  void dispose() {
    dio.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReadingTab(
      widget.viewPadding,
      api: api,
      onDispose: () {},
    );
  }
}
