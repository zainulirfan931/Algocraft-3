// Smoke test dasar untuk AlgoCraft.

import 'package:flutter_test/flutter_test.dart';

import 'package:game_irfan/main.dart';

void main() {
  testWidgets('AlgoCraftApp menampilkan shell utama', (WidgetTester tester) async {
    await tester.pumpWidget(const AlgoCraftApp());

    // Beranda memuat judul aplikasi dan navigasi bawah.
    expect(find.text('Sobat Kode'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });
}