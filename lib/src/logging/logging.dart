// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dio/dio.dart";
import "package:gallery/src/net/booru/safe_mode.dart";
import "package:gallery/src/net/cloudflare_exception.dart";
import "package:logging/logging.dart";

class LogReq {
  const LogReq(this.message, this.logger);

  final Logger logger;
  final String message;

  static String notes(int postId) => "notes $postId";
  static String completeTag(String str) => "complete tag $str";
  static String singlePost(
    int postId, {
    required String tags,
    required SafeMode safeMode,
  }) =>
      "single post $postId ($safeMode) tags: '$tags'";
  static String page(
    int page, {
    required String tags,
    required SafeMode safeMode,
  }) =>
      "page $page ($safeMode) tags: '$tags'";
  static String fromPost(int postId) => "from post $postId";
}

extension ReqLoggingExt on Dio {
  Future<Response<T>> getUriLog<T>(
    Uri uri,
    LogReq rdata, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final result = await getUri<T>(
        uri,
        data: data,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      rdata.logger.info(
        "${rdata.message}\nreq: result — ${result.statusCode}, ${result.statusMessage}",
      );

      return result;
    } catch (e, trace) {
      rdata.logger.warning(rdata.message, e, trace);

      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          throw CloudflareException();
        }
      }

      rethrow;
    }
  }
}
