import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/providers/api_client.dart';
import '../../utils/url_utils.dart';

bool voiceNoteSourceIsWebm(String url) {
  final storage = UrlUtils.mediaStoragePath(url)?.toLowerCase() ?? '';
  return storage.endsWith('.webm') || url.toLowerCase().contains('.webm');
}

class VoiceNotePlaybackHub {
  static AudioPlayer? activePlayer;

  static Future<void> stopExcept(AudioPlayer? current) async {
    if (activePlayer != null && activePlayer != current) {
      await activePlayer!.stop();
      activePlayer = null;
    }
  }
}

class VoiceNotePlayer extends StatefulWidget {
  final String url;
  final bool isMine;
  final int? durationSeconds;

  const VoiceNotePlayer({
    super.key,
    required this.url,
    required this.isMine,
    this.durationSeconds,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subs = [];

  bool _playing = false;
  bool _busy = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late final AnimationController _waveAnim;

  static const _barCount = 28;

  @override
  void initState() {
    super.initState();
    _waveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    _subs.add(_player.onPlayerComplete.listen((_) => _onComplete()));
    _subs.add(_player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      if (!mounted || d.inMilliseconds <= 0) return;
      setState(() => _duration = d);
    }));
  }

  void _onComplete() {
    if (!mounted) return;
    setState(() {
      _playing = false;
      _position = Duration.zero;
    });
  }

  @override
  void dispose() {
    if (VoiceNotePlaybackHub.activePlayer == _player) {
      VoiceNotePlaybackHub.activePlayer = null;
    }
    for (final s in _subs) {
      s.cancel();
    }
    _waveAnim.dispose();
    _player.dispose();
    super.dispose();
  }

  String get _playbackUrl => UrlUtils.mediaStreamUrl(widget.url);

  bool get _isWebm => voiceNoteSourceIsWebm(widget.url);

  Future<void> _configureAudioSession() async {
    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  Future<String> _cachedPlaybackFile() async {
    final playbackUrl = _playbackUrl;
    if (playbackUrl.isEmpty) {
      throw StateError('Invalid voice attachment URL');
    }
    final storage = UrlUtils.mediaStoragePath(widget.url) ?? 'voice';
    final safeName = storage.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ext = _isWebm ? 'm4a' : (storage.contains('.') ? storage.split('.').last : 'm4a');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/voice_$safeName.$ext');
    if (file.existsSync() && file.lengthSync() > 64) {
      return file.path;
    }
    await ApiClient().dio.download(playbackUrl, file.path);
    if (!file.existsSync() || file.lengthSync() < 64) {
      throw StateError('Voice file download failed');
    }
    return file.path;
  }

  Future<void> _startPlayback() async {
    await _configureAudioSession();
    final playbackUrl = _playbackUrl;
    if (playbackUrl.isEmpty) throw StateError('Invalid voice URL');

    final mime = _isWebm ? 'audio/mp4' : 'audio/mp4';
    try {
      await _player.play(UrlSource(playbackUrl, mimeType: mime));
      return;
    } catch (_) {}

    final path = await _cachedPlaybackFile();
    await _player.play(DeviceFileSource(path, mimeType: 'audio/mp4'));
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }

    _busy = true;
    await VoiceNotePlaybackHub.stopExcept(_player);
    VoiceNotePlaybackHub.activePlayer = _player;
    try {
      await _startPlayback();
      if (mounted) setState(() => _playing = true);
    } catch (e) {
      debugPrint('Voice playback error: $e');
      if (mounted) {
        Get.snackbar('voice_note'.tr, 'voice_playback_failed'.tr);
        setState(() => _playing = false);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _seekFromTap(double localX, double width) async {
    if (_duration.inMilliseconds <= 0 || width <= 0) return;
    final ratio = (localX / width).clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * ratio).round(),
    );
    await _player.seek(target);
    if (mounted) setState(() => _position = target);
  }

  String _formatClock(Duration d) {
    final total = d.inSeconds.clamp(0, 5999);
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _playing || _position.inSeconds > 0
        ? _formatClock(_position)
        : _formatClock(_duration);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: widget.isMine ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isMine ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFF4F46E5),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (d) => _seekFromTap(d.localPosition.dx, constraints.maxWidth),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4F46E5).withValues(alpha: 0.18),
                                  const Color(0xFF4F46E5).withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _waveAnim,
                        builder: (context, _) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(_barCount, (i) {
                              final base = 6.0 + ((i * 17) % 16);
                              final scale = _playing
                                  ? 0.55 + (_waveAnim.value * 0.45 * (i.isOdd ? 1.0 : 0.85))
                                  : 0.75;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: Container(
                                    height: base * scale,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCBD5E1),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
