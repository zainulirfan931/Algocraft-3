import 'package:flutter/material.dart';

void main() => runApp(const AlgoCraftApp());

class C {
  static const bg = Color(0xFFFFF4EA);
  static const green = Color(0xFF3BA10B);
  static const blue = Color(0xFF1E9BF0);
  static const orange = Color(0xFFFFA726);
  static const gold = Color(0xFFC8920A);
  static const brown = Color(0xFF5A3A1E);
  static const card = Color(0xFFFFE7D1);
}

class AlgoCraftApp extends StatelessWidget {
  const AlgoCraftApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AlgoCraft',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: C.bg,
          colorScheme: ColorScheme.fromSeed(seedColor: C.green),
        ),
        home: const MainShell(),
      );
}

// ---------- Shared widgets ----------
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  const BigButton(this.label, this.color, this.onTap, {this.icon, super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Color.lerp(color, Colors.black, .3)!, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: .5)),
          ]),
        ),
      );
}

class StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const StatChip(this.icon, this.color, this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      );
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatChip(Icons.shield, C.green, 'Pemula Kode'),
          Row(children: [
            StatChip(Icons.favorite, Colors.red, '3 Hari'),
            SizedBox(width: 6),
            StatChip(Icons.monetization_on, C.orange, '248'),
          ]),
        ]),
      );
}

class BlockTile extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const BlockTile(this.text, this.color, this.icon, {this.onTap, super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ]),
        ),
      );
}

// ---------- Shell with bottom navigation ----------
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onTab: (i) => setState(() => index = i)),
      const SandboxScreen(),
      const LevelMapScreen(),
      const CustomizeScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.science), label: 'Sandbox'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Peta'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Toko'),
        ],
      ),
    );
  }
}

// ---------- 1. Beranda ----------
class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onTab;
  const HomeScreen({required this.onTab, super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(children: [
          const TopBar(),
          const Text('ALGOCRAFT', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: C.green)),
          const Text('Petualangan Koding Dunia Voxel', style: TextStyle(fontSize: 12, color: C.brown)),
          Container(
            margin: const EdgeInsets.all(16),
            height: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8ED0F5), Color(0xFFCFF0FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Icon(Icons.smart_toy, size: 110, color: C.blue)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              BigButton('MULAI BERMAIN', C.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen())), icon: Icons.play_arrow),
              const SizedBox(height: 12),
              BigButton('MODE SANDBOX', C.blue, () => onTab(1), icon: Icons.science),
              const SizedBox(height: 12),
              BigButton('Kustomisasi Robot', C.brown, () => onTab(3), icon: Icons.palette),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: const Row(children: [
                  Icon(Icons.emoji_events, color: C.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('TANTANGAN HARIAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('Selesaikan 2 Misi Perulangan', style: TextStyle(fontSize: 12)),
                    ]),
                  ),
                  Text('+50 XP', style: TextStyle(color: C.green, fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ),
        ]),
      );
}

// ---------- 2. Tantangan Koding ----------
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});
  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  static const goalCol = 4;
  final List<String> program = [];
  int robotCol = 0;
  bool running = false;

  Future<void> run() async {
    if (running) return;
    setState(() { running = true; robotCol = 0; });
    for (final b in program) {
      final step = b.startsWith('Lompat') ? 2 : (b.startsWith('Maju') ? 1 : 0);
      for (var i = 0; i < step; i++) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        setState(() => robotCol = (robotCol + 1).clamp(0, 4));
      }
    }
    setState(() => running = false);
    if (robotCol == goalCol) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LevelCompleteScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum sampai tujuan, coba lagi!')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: C.bg,
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MISSION STAGE PLAYER', style: TextStyle(fontSize: 11, color: C.green, fontWeight: FontWeight.bold)),
            Text('Taman Awan', style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: 5 / 2.2,
              child: GridView.count(
                crossAxisCount: 5,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: List.generate(10, (i) {
                  final r = i ~/ 5, c = i % 5;
                  final isRobot = r == 0 && c == robotCol;
                  final isGoal = r == 0 && c == goalCol;
                  return Container(
                    decoration: BoxDecoration(color: const Color(0xFF9BE15D), borderRadius: BorderRadius.circular(8)),
                    child: Icon(isRobot ? Icons.smart_toy : (isGoal ? Icons.flag : null), color: isRobot ? C.blue : Colors.red),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Penyusun Blok', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12)),
                child: program.isEmpty
                    ? const Center(child: Text('Tambahkan blok di bawah'))
                    : ListView(children: [
                        const BlockTile('SETIAP DIMULAI', C.green, Icons.flag),
                        for (var i = 0; i < program.length; i++)
                          BlockTile(program[i], C.blue, Icons.arrow_forward, onTap: () => setState(() => program.removeAt(i))),
                      ]),
              ),
            ),
            const SizedBox(height: 8),
            const Text('PILIHAN BLOK PERINTAH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final b in ['Maju (1 Langkah)', 'Lompat (2 Langkah)', 'Belok'])
                ActionChip(label: Text(b), onPressed: () => setState(() => program.add(b))),
            ]),
            const SizedBox(height: 8),
            BigButton('JALANKAN KODE', C.green, run, icon: Icons.play_arrow),
          ]),
        ),
      );
}

// ---------- 3. Pilih Level ----------
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final levels = [
      ('1. Pendahuluan', 'done'),
      ('2. Pertanyaan Berurutan', 'done'),
      ('3. Perulangan Dasar', 'lock'),
      ('4. Lompat Rintangan', 'current'),
      ('5. Mindset Buku', 'lock'),
    ];
    return Column(children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Dunia 1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          StatChip(Icons.star, C.orange, '26 / 28'),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          itemCount: levels.length,
          itemBuilder: (_, i) {
            final (name, state) = levels[i];
            final color = state == 'done' ? C.green : state == 'current' ? C.blue : Colors.grey;
            return Align(
              alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(children: [
                  GestureDetector(
                    onTap: state == 'lock' ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen())),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: color,
                      child: Icon(state == 'lock' ? Icons.lock : state == 'done' ? Icons.check : Icons.smart_toy, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          },
        ),
      ),
      Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MISI AKTIF', style: TextStyle(fontSize: 10, color: C.green, fontWeight: FontWeight.bold)),
          const Text('Level 4: Lompat Rintangan', style: TextStyle(fontWeight: FontWeight.w800)),
          const Text('Buat Robot melompati rintangan untuk mencapai portal.', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          BigButton('AYO MULAI', C.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengeScreen()))),
        ]),
      ),
    ]);
  }
}

// ---------- 4. Level Selesai ----------
class LevelCompleteScreen extends StatelessWidget {
  const LevelCompleteScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.emoji_events, size: 90, color: C.orange),
              const SizedBox(height: 8),
              const Text('HORE! MISI BERHASIL!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.green)),
              const SizedBox(height: 16),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.star, size: 48, color: C.orange),
                Icon(Icons.star, size: 60, color: C.orange),
                Icon(Icons.star, size: 48, color: C.orange),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Text('6 Blok\n[Target: 4]', textAlign: TextAlign.center),
                  Text('+50 XP', style: TextStyle(color: C.green, fontWeight: FontWeight.bold)),
                  Text('+5 koin', style: TextStyle(color: C.orange, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 24),
              BigButton('LEVEL BERIKUTNYA', C.green, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChallengeScreen())), icon: Icons.arrow_forward),
              const SizedBox(height: 12),
              BigButton('ULANGI & SEMPURNAKAN', C.blue, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChallengeScreen())), icon: Icons.refresh),
              TextButton(onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Kembali ke Beranda')),
            ]),
          ),
        ),
      );
}

// ---------- 5. Mode Sandbox ----------
class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});
  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  final List<String> program = ['Maju (1 Langkah)', 'Ulangi Blok Besar', 'Kelakuan Robot'];
  int robot = 0;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Laboratorium Kreatif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            StatChip(Icons.restart_alt, C.blue, 'Reset'),
          ]),
          const Text('Eksplorasi bebas tanpa target, bereksperimen!', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.4,
            child: GridView.count(
              crossAxisCount: 7,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              children: List.generate(49, (i) => Container(
                    decoration: BoxDecoration(color: i == robot ? C.blue : const Color(0xFF9BE15D), borderRadius: BorderRadius.circular(4)),
                    child: i == robot ? const Icon(Icons.smart_toy, color: Colors.white, size: 14) : null,
                  )),
            ),
          ),
          const SizedBox(height: 12),
          const Text('KOLEKSI BLOK KODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          Wrap(spacing: 8, children: [
            for (final b in ['Maju', 'Putar Kiri', 'Putar Kanan', 'Loop'])
              ActionChip(label: Text(b), onPressed: () => setState(() => program.add(b))),
          ]),
          const SizedBox(height: 12),
          const Text('Urutan Program Sandbox', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (var i = 0; i < program.length; i++)
            BlockTile(program[i], i.isEven ? C.blue : C.green, Icons.drag_handle, onTap: () => setState(() => program.removeAt(i))),
          const SizedBox(height: 8),
          BigButton('JALANKAN EKSEKUSI', C.green, () => setState(() => robot = (robot + 1) % 49), icon: Icons.play_arrow),
        ]),
      );
}

// ---------- 6. Kustomisasi Karakter ----------
class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({super.key});
  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  Color robotColor = C.blue;
  int selected = 0;
  final items = const [
    ('Robo-Bit', 'Terpasang', Icons.smart_toy),
    ('Ksatria Vesel', 'Dimiliki', Icons.shield),
    ('Penyihir Kode', '150', Icons.auto_fix_high),
    ('Kucing Pixel', '150', Icons.pets),
    ('Ninja Cyber', '250', Icons.sports_martial_arts),
    ('Astronot Kubus', '300', Icons.rocket_launch),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            StatChip(Icons.monetization_on, C.orange, '248 Koin'),
            StatChip(Icons.code, C.blue, 'Pakaian Kode'),
          ]),
          const SizedBox(height: 12),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Icon(items[selected].$3, size: 100, color: robotColor),
          ),
          const SizedBox(height: 6),
          Center(child: Text(items[selected].$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
          const Text('WARNA BADAN ROBOT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            for (final c in [C.blue, Colors.red, C.orange, Colors.purple])
              GestureDetector(
                onTap: () => setState(() => robotColor = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: robotColor == c ? C.brown : Colors.transparent, width: 3)),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          const Text('Koleksi Kostum', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.1),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => selected = i),
              child: Container(
                decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected == i ? C.green : Colors.transparent, width: 3),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(items[i].$3, size: 44, color: C.brown),
                  Text(items[i].$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(items[i].$2, style: const TextStyle(fontSize: 11, color: C.gold)),
                ]),
              ),
            ),
          ),
        ]),
      );
}
