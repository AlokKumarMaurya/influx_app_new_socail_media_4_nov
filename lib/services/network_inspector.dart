import 'package:alice/alice.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug-only HTTP inspector. Alice provides a single draggable overlay
/// bubble with the recorded request count and opens the full request list.
class NetworkInspector {
  NetworkInspector._();

  static Alice? _alice;
  static AliceDioAdapter? _dioAdapter;

  static GlobalKey<NavigatorState>? get navigatorKey =>
      kDebugMode ? _alice?.getNavigatorKey() : null;

  static void initialize() {
    if (!kDebugMode || _alice != null) return;

    final configuration = AliceConfiguration(
      showOverlayBubble: true,
      maxCallsCount: 1000,
      redactedHeaders: {
        'authorization',
        'cookie',
        'set-cookie',
        'x-api-key',
      },
      redactedBodyKeys: {
        'password',
        'password_confirmation',
        'confirm_password',
        'token',
        'otp',
        'code',
        'access_token',
        'secret',
        'client_secret',
      },
    );

    _alice = Alice(configuration: configuration);
    _dioAdapter = AliceDioAdapter();
    _alice!.addAdapter(_dioAdapter!);
  }

  static void attachTo(Dio dio) {
    if (!kDebugMode) return;
    initialize();

    final adapter = _dioAdapter;
    if (adapter != null && !dio.interceptors.contains(adapter)) {
      dio.interceptors.add(adapter);
    }
  }

  static void showInspector() {
    if (kDebugMode) _alice?.showInspector();
  }
}
