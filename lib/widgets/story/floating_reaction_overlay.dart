import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

/// Controller to trigger floating reaction bursts.
class FloatingReactionController {
  _FloatingReactionOverlayState? _state;

  void trigger(String emoji, {Offset? origin}) {
    _state?.addBurst(emoji, origin: origin);
  }

  void _bind(_FloatingReactionOverlayState state) {
    _state = state;
  }

  void _unbind() {
    _state = null;
  }
}

class _ReactionParticle {
  final int id;
  final String emoji;
  final double startX;
  final double startY;
  final double travelDistance;
  final double swayAmplitude;
  final double swayCycles;
  final double size;
  final double peakScale;
  final double rotation;
  final int durationMs;
  final int delayMs;
  final int startTimeMs;

  _ReactionParticle({
    required this.id,
    required this.emoji,
    required this.startX,
    required this.startY,
    required this.travelDistance,
    required this.swayAmplitude,
    required this.swayCycles,
    required this.size,
    required this.peakScale,
    required this.rotation,
    required this.durationMs,
    required this.delayMs,
    required this.startTimeMs,
  });
}

/// Overlay that renders Instagram/Facebook-style floating reaction emoji bursts.
class FloatingReactionOverlay extends StatefulWidget {
  final FloatingReactionController controller;

  const FloatingReactionOverlay({
    super.key,
    required this.controller,
  });

  @override
  State<FloatingReactionOverlay> createState() => _FloatingReactionOverlayState();
}

class _FloatingReactionOverlayState extends State<FloatingReactionOverlay>
    with SingleTickerProviderStateMixin {
  final List<_ReactionParticle> _particles = [];
  final Random _random = Random();
  int _particleIdCounter = 0;
  Ticker? _ticker;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.controller._bind(this);
  }

  @override
  void didUpdateWidget(covariant FloatingReactionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._unbind();
      widget.controller._bind(this);
    }
  }

  @override
  void dispose() {
    widget.controller._unbind();
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  void _ensureTickerRunning() {
    if (_ticker == null) {
      _ticker = createTicker(_onTick);
      _ticker!.start();
    } else if (!_ticker!.isActive) {
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (_particles.isEmpty) {
      _ticker?.stop();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    bool needsRebuild = false;

    _particles.removeWhere((p) {
      final elapsedMs = now - p.startTimeMs - p.delayMs;
      if (elapsedMs >= p.durationMs) {
        needsRebuild = true;
        return true;
      }
      return false;
    });

    if (mounted && (needsRebuild || _particles.isNotEmpty)) {
      setState(() {});
    }
  }

  void addBurst(String emoji, {Offset? origin}) {
    if (!mounted) return;

    final defaultOrigin = Offset(
      _lastSize.width > 0 ? _lastSize.width / 2 : 200,
      _lastSize.height > 0 ? _lastSize.height - 120 : 600,
    );
    final baseOrigin = (origin != null && origin != Offset.zero) ? origin : defaultOrigin;

    final now = DateTime.now().millisecondsSinceEpoch;
    const particleCount = 5;

    for (int i = 0; i < particleCount; i++) {
      final isLeader = (i == 0);
      final jitterX = isLeader ? 0.0 : (_random.nextDouble() - 0.5) * 36.0;
      final jitterY = isLeader ? 0.0 : (_random.nextDouble() - 0.5) * 16.0;

      final startX = baseOrigin.dx + jitterX;
      final startY = baseOrigin.dy + jitterY;

      final travelDistance = isLeader
          ? 420.0 + _random.nextDouble() * 60.0
          : 360.0 + _random.nextDouble() * 120.0;
      final swayAmplitude = isLeader
          ? (_random.nextDouble() - 0.5) * 16.0
          : (18.0 + _random.nextDouble() * 22.0) * (_random.nextBool() ? 1.0 : -1.0);
      final swayCycles = 1.2 + _random.nextDouble() * 1.2;
      final size = isLeader
          ? 38.0
          : (24.0 + _random.nextDouble() * 8.0);
      final peakScale = isLeader ? 1.3 : (1.1 + _random.nextDouble() * 0.2);
      final rotation = (_random.nextDouble() - 0.5) * 0.35;
      final durationMs = isLeader ? 1600 : (1400 + _random.nextInt(350));
      final delayMs = isLeader ? 0 : (i * 60 + _random.nextInt(40));

      _particles.add(
        _ReactionParticle(
          id: _particleIdCounter++,
          emoji: emoji,
          startX: startX,
          startY: startY,
          travelDistance: travelDistance,
          swayAmplitude: swayAmplitude,
          swayCycles: swayCycles,
          size: size,
          peakScale: peakScale,
          rotation: rotation,
          durationMs: durationMs,
          delayMs: delayMs,
          startTimeMs: now,
        ),
      );
    }

    _ensureTickerRunning();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_particles.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        final children = <Widget>[];

        for (final p in _particles) {
          final elapsedMs = now - p.startTimeMs - p.delayMs;
          if (elapsedMs < 0) continue; // Waiting for delay

          final t = (elapsedMs / p.durationMs).clamp(0.0, 1.0);

          // Smooth cubic upward ease
          final verticalProgress = Curves.easeOutCubic.transform(t);
          final dy = p.startY - (verticalProgress * p.travelDistance);

          // Gentle swaying drift
          final dx = p.startX + (sin(t * pi * p.swayCycles) * p.swayAmplitude);

          // Scale: pops in quickly, maintains presence, then slight shrink at top
          double scale;
          if (t < 0.18) {
            scale = 0.4 + (p.peakScale - 0.4) * (t / 0.18);
          } else {
            scale = p.peakScale - (p.peakScale - 0.95) * ((t - 0.18) / 0.82);
          }

          // Opacity: stay 1.0 (fully visible) for first 70% so emojis stay crisp and vibrant!
          // Only fade out in the last 30% near the top.
          double opacity;
          if (t < 0.08) {
            opacity = (t / 0.08).clamp(0.0, 1.0);
          } else if (t < 0.70) {
            opacity = 1.0;
          } else {
            opacity = (1.0 - (t - 0.70) / 0.30).clamp(0.0, 1.0);
          }

          children.add(
            Positioned(
              left: dx - (p.size / 2),
              top: dy - (p.size / 2),
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: p.rotation * sin(t * pi),
                  child: Transform.scale(
                    scale: scale,
                    child: Text(
                      p.emoji,
                      style: TextStyle(
                        fontSize: p.size,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: children,
          ),
        );
      },
    );
  }
}
