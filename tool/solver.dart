// Pemeriksa apakah tiap level bisa diselesaikan dalam kapasitasnya.
// Jalankan: dart run tool/solver.dart
import 'dart:collection';

const kDr = [-1, 0, 1, 0]; // 0=atas 1=kanan 2=bawah 3=kiri
const kDc = [0, 1, 0, -1];

class Level {
  final int n;
  final String name;
  final List<String> palette;
  final int capacity;
  final int sr, sc, sd;
  final int gr, gc;
  final List<List<int>> rocks;
  const Level(this.n, this.name, this.palette, this.capacity, this.sr, this.sc,
      this.sd, this.gr, this.gc, this.rocks);
  bool rock(int r, int c) => rocks.any((p) => p[0] == r && p[1] == c);
  bool inside(int r, int c) => r >= 0 && r < 4 && c >= 0 && c < 4;
}

const levels = [
  Level(1, 'Menuju Kambing', ['maju'], 2, 3, 1, 1, 3, 3, []),
  Level(2, 'Batu / memutar', ['maju', 'kanan', 'kiri'], 8, 3, 0, 1, 3, 3,
      [
        [3, 1],
        [3, 2]
      ]),
  Level(3, 'Perulangan Dasar', ['maju', 'ulang'], 8, 3, 0, 1, 3, 3, []),
  Level(4, 'Lompat Rintangan', ['maju', 'lompat', 'kanan', 'kiri'], 8, 3, 0, 1, 3, 3,
      [
        [3, 2]
      ]),
  Level(5, 'Mindset Buku', ['maju', 'ulang', 'kanan', 'kiri', 'lompat'], 8, 3, 0, 1, 3, 3,
      [
        [3, 1],
        [3, 2]
      ]),
];

class St {
  final int r, c, d;
  final String? last;
  const St(this.r, this.c, this.d, this.last);
  @override
  bool operator ==(Object o) =>
      o is St && o.r == r && o.c == c && o.d == d && o.last == last;
  @override
  int get hashCode => Object.hash(r, c, d, last);
  @override
  String toString() => '($r,$c) d$d';
}

/// Menjalankan satu blok. null = gagal / tidak sah.
St? step(Level lv, St s, String id) {
  var r = s.r, c = s.c, d = s.d;
  switch (id) {
    case 'maju':
      return move(lv, r, c, d, 1, false, id);
    case 'maju2':
      return move(lv, r, c, d, 2, false, id);
    case 'lompat':
      return move(lv, r, c, d, 2, true, id);
    case 'kanan':
      return St(r, c, (d + 1) % 4, id);
    case 'kiri':
      return St(r, c, (d + 3) % 4, id);
    case 'ulang':
      final prev = s.last;
      if (prev == null) return null;
      return step(lv, St(r, c, d, null), prev);
    default:
      return null;
  }
}

St? move(Level lv, int r, int c, int d, int count, bool jump, String id) {
  for (var i = 0; i < count; i++) {
    final nr = r + kDr[d];
    final nc = c + kDc[d];
    final isLast = i == count - 1;
    if (!lv.inside(nr, nc)) return null;
    if (lv.rock(nr, nc) && !(jump && !isLast)) return null;
    r = nr;
    c = nc;
  }
  return St(r, c, d, id);
}

const _none = '__none__';

/// Urutan blok minimum untuk menyelesaikan level.
List<String>? solve(Level lv, int maxBlocks) {
  final start = St(lv.sr, lv.sc, lv.sd, _none);
  if (start.r == lv.gr && start.c == lv.gc) return [];
  final q = Queue<List<Object>>()..add([start, <String>[]]);
  final seen = <St>{start};
  while (q.isNotEmpty) {
    final node = q.removeFirst();
    final s = node[0] as St;
    final path = node[1] as List<String>;
    for (final id in lv.palette) {
      if (path.length >= maxBlocks) break;
      final ns = step(lv, s, id);
      if (ns == null) continue;
      final np = <String>[...path, id];
      if (ns.r == lv.gr && ns.c == lv.gc) return np;
      if (seen.contains(ns)) continue;
      seen.add(ns);
      q.add([ns, np]);
    }
  }
  return null;
}

void main() {
  var allOk = true;
  for (final lv in levels) {
    final sol = solve(lv, lv.capacity);
    if (sol == null) {
      allOk = false;
      print('L${lv.n} ${lv.name}: GAGAL - tidak ada solusi dalam ${lv.capacity} balok');
    } else {
      print('L${lv.n} ${lv.name}: ${sol.length} balok (kapasitas ${lv.capacity})');
      print('      ${sol.join(' -> ')}');
    }
  }
  print(allOk ? '\nSemua level solvable.' : '\nAda level yang mustahil.');
}