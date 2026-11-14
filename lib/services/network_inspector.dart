import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight, debug-only HTTP inspector with one draggable app-level launcher.
///
/// It records request metadata only; query parameters, headers and payloads are
/// deliberately omitted so credentials and personal data are not exposed.
class NetworkInspector {
  NetworkInspector._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final ValueNotifier<int> requestCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static final List<_NetworkCall> _calls = <_NetworkCall>[];

  static const int _maxCalls = 100;
  static const String _requestIdKey = '_networkInspectorRequestId';
  static int _nextId = 0;

  static void initialize() {
    // Kept as an explicit startup hook for main.dart.
  }

  static void attachTo(Dio dio) {
    if (!kDebugMode ||
        dio.interceptors.any((interceptor) =>
            interceptor is _NetworkInspectorInterceptor)) {
      return;
    }
    dio.interceptors.add(_NetworkInspectorInterceptor());
  }

  static void showInspector() {
    if (!kDebugMode) return;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const _NetworkInspectorPage(),
        ),
      ),
    );
  }

  static void clear() {
    _calls.clear();
    requestCount.value = 0;
    _revision.value++;
  }

  static int _recordRequest(RequestOptions options) {
    final id = ++_nextId;
    final safeUri = options.uri
        .replace(userInfo: '', query: '', fragment: '')
        .toString();
    _calls.insert(
      0,
      _NetworkCall(
        id: id,
        method: options.method.toUpperCase(),
        url: safeUri,
        startedAt: DateTime.now(),
      ),
    );
    if (_calls.length > _maxCalls) {
      _calls.removeRange(_maxCalls, _calls.length);
    }
    requestCount.value = _calls.length;
    _revision.value++;
    return id;
  }

  static void _completeRequest(
    RequestOptions options, {
    int? statusCode,
    String? error,
  }) {
    final id = options.extra[_requestIdKey] as int?;
    if (id == null) return;

    for (final call in _calls) {
      if (call.id == id) {
        call
          ..statusCode = statusCode
          ..error = error
          ..duration = DateTime.now().difference(call.startedAt);
        _revision.value++;
        return;
      }
    }
  }
}

class _NetworkInspectorInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra[NetworkInspector._requestIdKey] =
        NetworkInspector._recordRequest(options);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    NetworkInspector._completeRequest(
      response.requestOptions,
      statusCode: response.statusCode,
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    NetworkInspector._completeRequest(
      error.requestOptions,
      statusCode: error.response?.statusCode,
      error: error.type.name,
    );
    handler.next(error);
  }
}

class _NetworkCall {
  _NetworkCall({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
  });

  final int id;
  final String method;
  final String url;
  final DateTime startedAt;
  int? statusCode;
  Duration? duration;
  String? error;

  String get resultLabel {
    if (error != null) return 'Error: $error';
    return statusCode?.toString() ?? 'Pending';
  }
}

/// Place once in GetMaterialApp.builder, not inside individual pages/routes.
class NetworkInspectorLauncher extends StatefulWidget {
  const NetworkInspectorLauncher({super.key});

  @override
  State<NetworkInspectorLauncher> createState() =>
      _NetworkInspectorLauncherState();
}

class _NetworkInspectorLauncherState extends State<NetworkInspectorLauncher> {
  Offset _position = const Offset(12, 170);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLeft =
            (constraints.maxWidth - 112).clamp(0.0, double.infinity);
        final maxTop =
            (constraints.maxHeight - 58).clamp(0.0, double.infinity);
        final left = _position.dx.clamp(0.0, maxLeft);
        final top = _position.dy.clamp(0.0, maxTop);

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position = Offset(
                      (_position.dx + details.delta.dx).clamp(0.0, maxLeft),
                      (_position.dy + details.delta.dy).clamp(0.0, maxTop),
                    );
                  });
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: NetworkInspector.showInspector,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202124),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: NetworkInspector.requestCount,
                        builder: (context, count, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.travel_explore,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'HTTP $count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NetworkInspectorPage extends StatelessWidget {
  const _NetworkInspectorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network inspector'),
        actions: [
          IconButton(
            tooltip: 'Clear requests',
            onPressed: NetworkInspector.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: NetworkInspector._revision,
        builder: (context, _, __) {
          if (NetworkInspector._calls.isEmpty) {
            return const Center(child: Text('No network requests captured yet.'));
          }

          return ListView.separated(
            itemCount: NetworkInspector._calls.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final call = NetworkInspector._calls[index];
              final duration = call.duration;
              final subtitle = <String>[
                call.resultLabel,
                if (duration != null) '${duration.inMilliseconds} ms',
                call.startedAt.toLocal().toIso8601String(),
              ].join(' • ');

              return ListTile(
                dense: true,
                title: Text(
                  '${call.method}  ${call.url}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(subtitle),
              );
            },
          );
        },
      ),
    );
  }
}
