import 'package:alice/alice.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug-only HTTP inspector with one app-level, draggable launcher.
class NetworkInspector {
  NetworkInspector._();

  static Alice? _alice;
  static AliceDioAdapter? _dioAdapter;
  // Alice must share the app's root navigator key so showInspector()
  // can push its inspector route onto the visible GetMaterialApp navigator.
  static GlobalKey<NavigatorState>? get navigatorKey =>
      kDebugMode ? _alice?.getNavigatorKey() : null;
  static final ValueNotifier<int> requestCount = ValueNotifier<int>(0);

  static void initialize() {
    if (!kDebugMode || _alice != null) return;

    final configuration = AliceConfiguration(
      // Alice's built-in bubble can be recreated by route changes. Use our
      // single app-root launcher instead.
      showOverlayBubble: false,
      redactedHeaders: {
        'authorization', 'cookie', 'set-cookie', 'x-api-key',
      },
      redactedBodyKeys: {
        'password', 'password_confirmation', 'confirm_password', 'token',
        'otp', 'code', 'access_token', 'secret', 'client_secret',
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
      if (!dio.interceptors.any((item) => item is _RequestCounterInterceptor)) {
        dio.interceptors.add(_RequestCounterInterceptor());
      }
    }
  }

  static void showInspector() {
    if (kDebugMode) _alice?.showInspector();
  }
}

class _RequestCounterInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    NetworkInspector.requestCount.value++;
    handler.next(options);
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
        final maxLeft = (constraints.maxWidth - 112).clamp(0.0, double.infinity);
        final maxTop = (constraints.maxHeight - 58).clamp(0.0, double.infinity);
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
                        horizontal: 13, vertical: 10,
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
                            const Icon(Icons.travel_explore,
                                color: Colors.white, size: 18),
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
