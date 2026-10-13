import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan progres pemain: bintang per level, XP, dan koin.
///
/// - Disimpan sebagai satu JSON di SharedPreferences (kunci `progress_v1`)
///   sehingga bertahan setelah aplikasi ditutup dan dibuka lagi.
/// - Aturan kunci progresif: level N terbuka kalau level N-1 sudah pernah
///   selesai (minimal 1 bintang). Level pertama selalu terbuka.
/// - [changes] berdenyut setiap kali data berubah supaya UI (pil XP/koin,
///   kartu progres, peta level) bisa memperbarui diri sendiri.
class GameProgress {
  GameProgress._();
  static final GameProgress instance = GameProgress._();

  static const _key = 'progress_v1';

  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Bintang terbaik per nomor level (level yang belum pernah selesai
  /// tidak punya entri).
  final Map<int, int> _stars = {};

  /// Id kostum yang sudah dibeli di Toko Kostum.
  final Set<String> _owned = {};

  /// Kostum yang sedang dipakai per kategori (nama kategori → id item).
  final Map<String, String> _equipped = {};

  int xp = 0;
  int coins = 0;
  bool _loaded = false;

  /// Muat progres tersimpan. Panggil sekali dari main().
  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      xp = (data['xp'] as num?)?.toInt() ?? 0;
      coins = (data['coins'] as num?)?.toInt() ?? 0;
      final saved = Map<String, dynamic>.from(
          (data['stars'] as Map?) ?? const <String, dynamic>{});
      _stars
        ..clear()
        ..addAll({
          for (final e in saved.entries)
            int.parse(e.key): (e.value as num).toInt(),
        });
      _owned
        ..clear()
        ..addAll(((data['owned'] as List?) ?? const [])
            .map((e) => '$e'));
      _equipped
        ..clear()
        ..addAll({
          for (final e
              in ((data['equipped'] as Map?) ?? const <String, dynamic>{})
                  .entries)
            '${e.key}': '${e.value}',
        });
      changes.value++;
    } catch (_) {
      // Penyimpanan tidak tersedia — mulai dari awal tanpa mengganggu game.
    }
  }

  /// Bintang terbaik yang pernah diraih di level [number] (0 kalau belum).
  int starsOf(int number) => _stars[number] ?? 0;

  /// Total bintang seluruh level.
  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  /// Apakah level [number] terbuka? (progresif: butuh bintang level sebelumnya)
  bool isUnlocked(int number) => number <= 1 || starsOf(number - 1) > 0;

  /// Catat kemenangan level: bintang disimpan yang terbaik dari semua
  /// percobaan, XP & koin selalu ditambahkan sesuai hadiah level.
  Future<void> recordWin({
    required int number,
    required int stars,
    required int xpGain,
    required int coinGain,
  }) async {
    if (stars > starsOf(number)) _stars[number] = stars;
    xp += xpGain;
    coins += coinGain;
    changes.value++;
    await _save();
  }

  /// Apakah kostum [id] sudah dimiliki?
  bool ownsItem(String id) => _owned.contains(id);

  /// Apakah item [id] di kategori [category] sedang dipakai?
  bool isItemEquipped(String category, String id) =>
      _equipped[category] == id;

  /// Beli kostum [id] seharga [price] koin. Gagal (return false) kalau
  /// sudah dimiliki atau koin tidak cukup.
  Future<bool> buyItem(String id, int price) async {
    if (_owned.contains(id) || coins < price) return false;
    coins -= price;
    _owned.add(id);
    changes.value++;
    await _save();
    return true;
  }

  /// Pakai kostum [id] di kategori [category]. Item harus sudah dimiliki.
  Future<void> equipItem(String category, String id) async {
    if (!_owned.contains(id) || _equipped[category] == id) return;
    _equipped[category] = id;
    changes.value++;
    await _save();
  }

  /// Lepas kostum yang sedang dipakai di kategori [category].
  Future<void> unequipItem(String category) async {
    if (_equipped.remove(category) == null) return;
    changes.value++;
    await _save();
  }

  /// Hanya untuk test — kembalikan semua progres ke keadaan kosong.
  @visibleForTesting
  void reset() {
    _stars.clear();
    _owned.clear();
    _equipped.clear();
    xp = 0;
    coins = 0;
    _loaded = false;
    changes.value++;
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        jsonEncode({
          'xp': xp,
          'coins': coins,
          'stars': {for (final e in _stars.entries) '${e.key}': e.value},
          'owned': _owned.toList(),
          'equipped': _equipped,
        }),
      );
    } catch (_) {
      // Gagal menyimpan — data tetap hidup di memori selama sesi berjalan.
    }
  }
}
