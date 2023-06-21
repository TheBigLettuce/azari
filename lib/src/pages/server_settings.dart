import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/db/isar.dart';
import 'package:gallery/src/schemas/server_settings.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  ServerSettings settings =
      isar().serverSettings.getSync(0) ?? ServerSettings.empty();

  final SkeletonState skeletonState = SkeletonState.settings();

  bool? isConnected;
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;

    skeletonState.dispose();

    super.dispose();
  }

  void _checkServer(Uri url, void Function() onSuccess) async {
    try {
      var resp = await get(url.replace(path: "/hello"));
      if (resp.statusCode != 200) {
        throw "not 200";
      }

      onSuccess();
    } catch (e, trace) {
      log("checking server status",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }
  }

  void _newDeviceId(String key, void Function() onSuccess) async {
    try {
      var req = MultipartRequest(
          "POST",
          Uri.parse(
            settings.host,
          ).replace(path: "/device/register", queryParameters: {"key": key}));

      var resp = await req.send();

      if (resp.statusCode != 200) {
        throw "not 200";
      }

      var bytes = await resp.stream.toBytes();

      isar().writeTxnSync(() {
        isar().serverSettings.putSync(settings.copy(deviceId: bytes));
      });

      onSuccess();
    } catch (e, trace) {
      log("setting deviceId",
          level: Level.WARNING.value, error: e, stackTrace: trace);
    }
  }

  void _checkConnectivity() {
    try {
      _checkServer(
          Uri.parse(
            settings.host,
          ), () {
        if (!isDisposed) {
          setState(() {
            isConnected = true;
          });
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return makeSkeletonInnerSettings(
        context, "Server settings", skeletonState, [
      ListTile(
        trailing: TextButton(
          onPressed: () {
            Navigator.push(
                context,
                DialogRoute(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: TextField(
                          onSubmitted: (value) {
                            try {
                              var uri = Uri.parse(value);

                              if (!uri.hasScheme) {
                                throw AppLocalizations.of(context)!
                                    .schemeIsRequired;
                              }

                              _checkServer(uri, () {
                                isar().writeTxnSync(
                                  () {
                                    isar().serverSettings.putSync(
                                        settings.copy(host: uri.toString()));
                                  },
                                );

                                if (!isDisposed) {
                                  setState(() {
                                    settings =
                                        isar().serverSettings.getSync(0)!;
                                    isConnected = true;
                                  });

                                  Navigator.pop(context);
                                }
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .notAValidUrl(e.toString()))));
                            }
                          },
                        ),
                      );
                    }));
          },
          child: Text(AppLocalizations.of(context)!.changeServerUrl),
        ),
        leading: isConnected == null
            ? IconButton(
                onPressed: _checkConnectivity, icon: const Icon(Icons.refresh))
            : isConnected!
                ? IconButton(
                    icon: const Icon(Icons.check),
                    color: Colors.green,
                    onPressed: _checkConnectivity,
                  )
                : IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.red,
                    onPressed: _checkConnectivity,
                  ),
        title: Text(AppLocalizations.of(context)!.serverAddress),
        subtitle: settings.host.isEmpty
            ? Text(
                AppLocalizations.of(context)!.emptyValue,
                style: const TextStyle(fontStyle: FontStyle.italic),
              )
            : Text(settings.host),
      ),
      ListTile(
        trailing: TextButton(
          onPressed: settings.host.isEmpty
              ? null
              : () {
                  Navigator.push(
                      context,
                      DialogRoute(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title:
                                  Text(AppLocalizations.of(context)!.enterKey),
                              content: TextField(
                                onSubmitted: (value) {
                                  _newDeviceId(value, () {
                                    if (!isDisposed) {
                                      setState(() {
                                        settings =
                                            isar().serverSettings.getSync(0)!;
                                      });

                                      Navigator.pop(context);
                                    }
                                  });
                                },
                              ),
                            );
                          }));
                },
          child: Text(AppLocalizations.of(context)!.changeDeviceId),
        ),
        title: Text(AppLocalizations.of(context)!.deviceId),
        subtitle: settings.deviceId.isEmpty
            ? Text(
                AppLocalizations.of(context)!.emptyValue,
                style: const TextStyle(fontStyle: FontStyle.italic),
              )
            : Text(hex.encode(settings.deviceId)),
      )
    ]);
  }
}
