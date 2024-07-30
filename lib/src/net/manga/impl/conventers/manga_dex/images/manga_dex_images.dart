// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/net/manga/manga_api.dart";
import "package:json_annotation/json_annotation.dart";

part "manga_dex_images.g.dart";

@JsonSerializable()
class MangaDexImages {
  const MangaDexImages({
    required this.baseUrl,
    required this.data,
    required this.result,
  });

  factory MangaDexImages.fromJson(Map<String, dynamic> json) =>
      _$MangaDexImagesFromJson(json);

  @JsonKey(name: "result")
  final String result;

  @JsonKey(name: "baseUrl")
  final String baseUrl;

  @JsonKey(name: "chapter")
  final _Chapter? data;

  List<MangaImage> emptyIfNotOk() => result != "ok"
      ? const []
      : data!.images.indexed
          .map(
            (e) => MangaImage(
              "$baseUrl/data/${data!.hash}/${e.$2}",
              e.$1,
              data!.images.length,
            ),
          )
          .toList();
}

@JsonSerializable()
class _Chapter {
  const _Chapter({
    required this.hash,
    required this.images,
    required this.imagesCompressed,
  });

  factory _Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);

  @JsonKey(name: "hash")
  final String hash;

  @JsonKey(name: "data")
  final List<String> images;

  @JsonKey(name: "dataSaver")
  final List<String>? imagesCompressed;
}
