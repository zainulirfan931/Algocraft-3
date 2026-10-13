// Smoke test dasar untuk AlgoCraft.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_irfan/game_progress.dart';
import 'package:game_irfan/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

MissionLevel levelByNumber(int n) =>
    kLevels.firstWhere((l) => l.number == n);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Store in-memory supaya GameProgress bisa menyimpan & muat ulang di test.
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('AlgoCraftApp menampilkan shell utama', (WidgetTester tester) async {
    await tester.pumpWidget(const AlgoCraftApp());

    // Beranda memuat judul aplikasi dan navigasi bawah.
    expect(find.text('Halo Sobat Kode! 🚀'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('Level 6 dan 7 tersedia di daftar level',
      (WidgetTester tester) async {
    expect(kLevels.length, 7);
    expect(levelByNumber(6).title, 'Dinding Pertama');
    expect(levelByNumber(7).title, 'Sisa Rumah');
    expect(levelByNumber(6).hasBuild, isTrue);
    expect(levelByNumber(7).hasBuild, isTrue);
  });

  /// Menambahkan balok lewat palet (palet selalu setelah panel kode,
  /// jadi pencocokan terakhir adalah entri palet).
  Future<void> addBlock(WidgetTester tester, String code) async {
    final finder = find.text(code).last;
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> runUntilSelesai(WidgetTester tester) async {
    final tombol = find.text('JALANKAN');
    await tester.ensureVisible(tombol);
    await tester.pump();
    await tester.tap(tombol);
    for (var i = 0; i < 100; i++) {
      if (find.text('HORE! MISI BERHASIL!').evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('Level 6 selesai dengan place + ulangi_blok(4)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(home: ChallengeScreen(level: levelByNumber(6))));

    expect(find.textContaining('repeat loop'), findsOneWidget);

    await addBlock(tester, 'place("kayu")');
    await addBlock(tester, 'gerak_maju()');
    await addBlock(tester, 'ulangi_blok(4)');
    expect(find.text('3 / 5 balok'), findsOneWidget);

    await runUntilSelesai(tester);
    expect(find.text('HORE! MISI BERHASIL!'), findsOneWidget);
    expect(find.text('Level 6: Dinding Pertama'), findsOneWidget);

    // progres tersimpan: bintang, XP, koin, dan kunci level berikutnya
    final prog = GameProgress.instance;
    expect(prog.starsOf(6), 3);
    expect(prog.isUnlocked(7), isTrue);
    expect(prog.xp, greaterThanOrEqualTo(levelByNumber(6).reward));
    expect(prog.coins, greaterThanOrEqualTo(levelByNumber(6).reward ~/ 10));
  });

  testWidgets('Level 7 selesai dengan place + ulangi_blok(3)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        MaterialApp(home: ChallengeScreen(level: levelByNumber(7))));

    expect(find.textContaining('Bangunlah sisa rumah Anda'), findsOneWidget);

    await addBlock(tester, 'place("kayu")');
    await addBlock(tester, 'gerak_maju()');
    await addBlock(tester, 'ulangi_blok(3)');
    await addBlock(tester, 'belok_kiri()');
    await addBlock(tester, 'place("batu")');
    await addBlock(tester, 'gerak_maju()');
    await addBlock(tester, 'place("kayu")');
    await addBlock(tester, 'gerak_maju()');
    expect(find.text('8 / 9 balok'), findsOneWidget);

    await runUntilSelesai(tester);
    expect(find.text('HORE! MISI BERHASIL!'), findsOneWidget);
    expect(find.text('Level 7: Sisa Rumah'), findsOneWidget);

    final prog = GameProgress.instance;
    expect(prog.starsOf(7), 3);
    expect(prog.xp, greaterThanOrEqualTo(
        levelByNumber(6).reward + levelByNumber(7).reward));
  });

  testWidgets('Progres disimpan: rekam menang, muat ulang, kunci peta',
      (WidgetTester tester) async {
    final prog = GameProgress.instance;
    prog.reset();

    expect(prog.isUnlocked(1), isTrue);
    expect(prog.isUnlocked(2), isFalse);

    await prog.recordWin(number: 1, stars: 3, xpGain: 50, coinGain: 5);
    expect(prog.starsOf(1), 3);
    expect(prog.totalStars, 3);
    expect(prog.xp, 50);
    expect(prog.coins, 5);
    expect(prog.isUnlocked(2), isTrue);

    // percobaan ulang tidak menurunkan bintang terbaik
    await prog.recordWin(number: 1, stars: 2, xpGain: 50, coinGain: 5);
    expect(prog.starsOf(1), 3);
    expect(prog.xp, 100);

    // simulasi tutup lalu buka aplikasi lagi
    prog.reset();
    await prog.init();
    expect(prog.starsOf(1), 3);
    expect(prog.xp, 100);
    expect(prog.coins, 10);

    // peta level: gembok untuk level yang belum terbuka + jumlah bintang
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LevelMapScreen())));
    expect(find.text('Dunia 1'), findsOneWidget);
    final maxStars = kLevels.fold<int>(0, (a, l) => a + l.starTarget);
    expect(find.text('${prog.totalStars} / $maxStars'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });
}
