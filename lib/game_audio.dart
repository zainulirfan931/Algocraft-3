import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengelola audio game: musik latar (loop) + efek suara satu-kali.
///
/// - Status on/off dan volume disimpan lewat [SharedPreferences].
/// - Semua pemanggilan otomatis diabaikan saat test widget
///   (plugin audio tidak tersedia di lingkungan test).
/// - Musik bisa saja ditahan kebijakan autoplay browser; audio akan
///   dicoba lagi otomatis pada interaksi pengguna berikutnya.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  /// Bertambah setiap kali on/off atau volume berubah — dipakai UI
  /// (tombol speaker dan slider) untuk mendengarkan perubahan.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  bool soundOn = true;
  double volume = .7;

  AudioPlayer? _bgm;
  final Map<String, AudioPlayer> _sfx = {};
  bool _inited = false;

  /// True saat berjalan di test widget (FLUTTER_TEST=1).
  bool get _skip =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// Muat preferensi lalu mulai musik. Panggil sekali dari main().
  Future<void> init() async {
    if (_inited || _skip) return;
    _inited = true;
    try {
      final p = await SharedPreferences.getInstance();
      soundOn = p.getBool('sound_on') ?? true;
      volume = p.getDouble('volume') ?? .7;
      changes.value++;
    } catch (_) {
      // Preferensi tidak tersedia — pakai default.
    }
    if (soundOn) _playBgm();
  }

  void _playBgm() {
    if (_skip || !soundOn || volume <= 0) return;
    try {
      final player = _bgm ??= AudioPlayer();
      player.setReleaseMode(ReleaseMode.loop);
      player.setVolume((volume * .55).clamp(0, 1));
      unawaited(player.play(AssetSource('audio/bgm.wav')).catchError((_) {}));
    } catch (_) {
      // Audio tidak didukung di perangkat ini — diamkan.
    }
  }

  /// Coba jalankan musik lagi kalau belum jalan (mis. tahan autoplay).
  void _resumeBgm() {
    if (_bgm == null) {
      _playBgm();
    } else if (_bgm!.state != PlayerState.playing) {
      _playBgm();
    }
  }

  /// Mainkan efek suara sekali. [name] = nama file di assets/audio
  /// tanpa ekstensi, mis. 'click', 'place', 'win', 'fail'.
  Future<void> playSfx(String name) async {
    if (_skip || !soundOn || volume <= 0) return;
    _resumeBgm();
    try {
      final player = _sfx[name] ??= AudioPlayer();
      await player.stop();
      await player.setVolume(volume.clamp(0, 1));
      await player.play(AssetSource('audio/$name.wav'));
    } catch (_) {
      // Gagal diputar — abaikan.
    }
  }

  /// Nyalakan/matikan semua suara.
  Future<void> setSoundOn(bool on) async {
    soundOn = on;
    changes.value++;
    _savePrefs();
    if (on) {
      _playBgm();
      return;
    }
    try {
      await _bgm?.stop();
      for (final p in _sfx.values) {
        await p.stop();
      }
    } catch (_) {}
  }

  /// Atur volume 0..1 (untuk musik maupun efek berikutnya).
  void setVolume(double v) {
    volume = v.clamp(0, 1);
    changes.value++;
    _savePrefs();
    try {
      _bgm?.setVolume((volume * .55).clamp(0, 1));
    } catch (_) {}
  }

  void _savePrefs() {
    if (_skip) return;
    unawaited(_savePrefsAsync());
  }

  Future<void> _savePrefsAsync() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('sound_on', soundOn);
      await p.setDouble('volume', volume);
    } catch (_) {}
  }
}
