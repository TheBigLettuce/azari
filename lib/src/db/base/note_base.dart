// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/contentable.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:isar/isar.dart';

class NoteBase implements Cell {
  NoteBase(
    this.text,
    this.time, {
    required this.backgroundColor,
    required this.textColor,
  });

  @Index(caseSensitive: false, type: IndexType.hash)
  final List<String> text;
  @Index()
  final DateTime time;

  final int? backgroundColor;
  final int? textColor;

  @override
  Contentable content() => const EmptyContent();

  @override
  ImageProvider<Object>? thumbnail() => null;

  @override
  Key uniqueKey() => throw UnimplementedError();

  @override
  Widget? contentInfo(BuildContext context) => null;

  @override
  List<(IconData, void Function()?)>? addStickers(BuildContext context) {
    return null;
  }

  @override
  String alias(bool isList) {
    return "";
  }

  @override
  String? fileDownloadUrl() => null;

  @override
  Id? isarId;

  @override
  List<Widget>? addButtons(BuildContext context) => null;

  @override
  List<Sticker> stickers(BuildContext context) => const [];
}
