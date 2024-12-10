// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

abstract interface class DownloadFileService implements ServiceMarker {
  List<DownloadFileData> get inProgressAll;
  List<DownloadFileData> get failedAll;

  void saveAll(List<DownloadFileData> l);
  void deleteAll(List<String> urls);

  DownloadFileData? get(String url);
  bool exist(String url);
  bool notExist(String url) => !exist(url);

  DownloadFileData? next();
  List<DownloadFileData> nextNumber(int minus);

  void markInProgressAsFailed();
  void clear();
}

@immutable
abstract class DownloadFileData implements CellBase, Thumbnailable {
  const factory DownloadFileData({
    required DownloadStatus status,
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) = $DownloadFileData;

  factory DownloadFileData.d({
    required String name,
    required String url,
    required String thumbUrl,
    required String site,
    required DateTime date,
  }) =>
      DownloadFileData(
        status: DownloadStatus.inProgress,
        name: name,
        url: url,
        thumbUrl: thumbUrl,
        site: site,
        date: date,
      );

  String get url;
  String get name;
  String get thumbUrl;
  DateTime get date;
  String get site;
  DownloadStatus get status;

  DownloadFileData toInProgress();
  DownloadFileData toFailed();
  DownloadFileData toOnHold();
}

@immutable
abstract class DownloadFileDataImpl
    with DefaultBuildCellImpl
    implements DownloadFileData {
  const DownloadFileDataImpl();

  @override
  String toString() => "Download${status.name}: $name, url: $url";

  @override
  Key uniqueKey() => ValueKey(url);

  @override
  ImageProvider<Object> thumbnail(BuildContext? context) =>
      CachedNetworkImageProvider(thumbUrl);

  @override
  String alias(bool isList) => name;

  @override
  CellStaticData description() => const CellStaticData();
}
