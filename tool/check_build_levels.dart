// Pemeriksa cepat level 6 & 7 (fitur place + ulangi_blok(3)/(4)).
// Meniru mesin game: balok isi loop TIDAK dijalankan di alur utama,
// hanya oleh balok ulangi_blok-nya.
// Jalankan: dart run tool/check_build_levels.dart
const kDr = [-1, 0, 1, 0]; // 0=atas 1=kanan 2=bawah 3=kiri
const kDc = [0, 1, 0, -1];

class BuildLevel {
  final int n, sr, sc, sd, capacity, par;
  final String name;
  final List<List<int>> walls;
  const BuildLevel(this.name, this.n, this.sr, this.sc, this.sd, this.capacity,
      this.par, this.walls);
}

const level6 = BuildLevel('Dinding Pertama', 5, 0, 0, 2, 5, 3, [
  [1, 0],
  [2, 0],
  [3, 0],
  [4, 0],
]);

const level7 = BuildLevel('Sisa Rumah', 5, 0, 0, 2, 9, 8, [
  [1, 0],
  [2, 0],
  [3, 0],
  [3, 1],
  [3, 2],
]);

bool isRepeat(String id) => id == 'ulang' || id == 'ulang3' || id == 'ulang4';

int repeatTimes(String id) => id == 'ulang' ? 2 : (id == 'ulang3' ? 3 : 4);

/// Balok repeat pertama setelah index i, atau -1.
/// 'ulang' lama tidak menarik balok ke loop (dijalankan bertahap).
int repeatOwner(List<String> prog, int i) {
  for (var j = i + 1; j < prog.length; j++) {
    if (!isRepeat(prog[j])) continue;
    return prog[j] == 'ulang' ? -1 : j;
  }
  return -1;
}

int groupStart(List<String> prog, int at) {
  for (var i = at - 1; i >= 0; i--) {
    if (isRepeat(prog[i])) return i + 1;
  }
  return 0;
}

/// true = semua petak area bangunan terpasang papan.
bool run(BuildLevel lv, List<String> prog, {bool trace = false}) {
  var r = lv.sr, c = lv.sc, d = lv.sd;
  final placed = <String>{};
  final log = <String>[];

  bool exec(String id) {
    switch (id) {
      case 'maju':
        final nr = r + kDr[d], nc = c + kDc[d];
        if (nr < 0 || nr >= lv.n || nc < 0 || nc >= lv.n) {
          log.add('GAGAL maju ke ($nr,$nc) di luar papan');
          return false;
        }
        r = nr;
        c = nc;
        return true;
      case 'kanan':
        d = (d + 1) % 4;
        return true;
      case 'kiri':
        d = (d + 3) % 4;
        return true;
      case 'place':
      case 'placeBatu':
        final fr = r + kDr[d], fc = c + kDc[d];
        if (fr < 0 || fr >= lv.n || fc < 0 || fc >= lv.n) {
          log.add('GAGAL place di luar papan ($fr,$fc)');
          return false;
        }
        if (!lv.walls.any((w) => w[0] == fr && w[1] == fc)) {
          log.add('GAGAL place di ($fr,$fc): bukan area bangunan');
          return false;
        }
        placed.add('$fr,$fc');
        log.add('place($fr,$fc) robot=($r,$c)');
        return true;
      default:
        log.add('GAGAL balok tak dikenal: $id');
        return false;
    }
  }

  for (var i = 0; i < prog.length; i++) {
    final id = prog[i];
    if (isRepeat(id)) {
      if (i == 0) {
        log.add('GAGAL repeat di urutan pertama');
        return false;
      }
      if (id == 'ulang') {
        if (!exec(prog[i - 1])) return false;
        if (!exec(prog[i - 1])) return false;
        continue;
      }
      final start = groupStart(prog, i);
      if (start >= i) {
        log.add('GAGAL $id tanpa balok di atasnya');
        return false;
      }
      log.add('${repeatTimes(id)}x ${start + 1}-$i: $id');
      for (var k = 0; k < repeatTimes(id); k++) {
        for (var j = start; j < i; j++) {
          if (!exec(prog[j])) return false;
        }
      }
      continue;
    }
    if (repeatOwner(prog, i) >= 0) continue; // isi loop
    if (!exec(id)) return false;
  }

  final win = lv.walls.every((w) => placed.contains('${w[0]},${w[1]}'));
  if (trace) {
    for (final l in log) {
      print('      $l');
    }
    print('      papan: ${placed.length}/${lv.walls.length} unik · '
        'robot akhir ($r,$c) · balok ${prog.length}/${lv.capacity}'
        ' · par ${lv.par}');
  }
  return win;
}

bool fail = false;

void check(String label, BuildLevel lv, List<String> prog,
    {bool expect = true}) {
  final ok = run(lv, prog, trace: true);
  final fits = prog.length <= lv.capacity;
  final stars = prog.length <= lv.par;
  final good = ok == expect && (!expect || (fits && stars));
  print('$label: ${ok ? "MENANG" : "GAGAL"} · kapasitas ${fits ? "OK" : "LEWAT"}'
      ' · 3 bintang ${stars ? "OK" : "TIDAK"}');
  if (!good) fail = true;
}

void main() {
  print('L6 Dinding Pertama — place, maju, ulangi_blok(4)');
  check('L6', level6, ['place', 'maju', 'ulang4']);
  print('\nL6 salah urutan (maju dulu) — harus gagal');
  check('L6-', level6, ['maju', 'place', 'ulang4'], expect: false);

  print('\nL7 Sisa Rumah — place, maju, ulangi_blok(3), kiri, place, maju, '
      'place, maju');
  check('L7', level7,
      ['place', 'maju', 'ulang3', 'kiri', 'place', 'maju', 'place', 'maju']);

  print('\nL7 versi loop kedua — place, maju, ulangi_blok(3), kiri, '
      'place, maju, ulangi_blok(3)');
  check('L7b', level7,
      ['place', 'maju', 'ulang3', 'kiri', 'place', 'maju', 'ulang3'],
      expect: false);

  print(fail ? '\nAda masalah.' : '\nKedua level beres dan solvable.');
}
