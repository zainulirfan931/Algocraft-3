// Pembuat aset audio AlgoCraft — gaya MAHJONG (WAV PCM 16-bit mono, 22050 Hz).
//
//   assets/audio/bgm.wav   — musik latar pentatonik (loop 8 bar, 120 BPM,
//                            petikan koto/zheng + taiko + ketukan kepingan)
//   assets/audio/click.wav — klik kepingan mahjong ("tik-tik")
//   assets/audio/place.wav — kepingan diletakkan ("kluk-thud")
//   assets/audio/win.wav   — gong menang + lari nada pentatonik
//   assets/audio/fail.wav  — kepingan jatuh + nada turun
//
// Jalankan: dart run tool/gen_audio.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sr = 22050;

void main() {
  final dir = Directory('assets/audio');
  dir.createSync(recursive: true);

  final tracks = <String, List<double>>{
    'bgm': makeBgm(),
    'click': makeClick(),
    'place': makePlace(),
    'win': makeWin(),
    'fail': makeFail(),
  };

  tracks.forEach((name, samples) {
    final bytes = encodeWav(samples);
    File('assets/audio/$name.wav').writeAsBytesSync(bytes);
    final kb = (bytes.length / 1024).toStringAsFixed(0);
    final sec = (samples.length / sr).toStringAsFixed(2);
    stdout.writeln('assets/audio/$name.wav — $kb KB, $sec s');
  });
}

// ─────────────────────────────────────────────────────────────
// WAV ENCODER
// ─────────────────────────────────────────────────────────────
List<int> encodeWav(List<double> samples) {
  var peak = 0.0;
  for (final s in samples) {
    if (s.abs() > peak) peak = s.abs();
  }
  final gain = peak > 0 ? 0.9 / peak : 1.0;

  final n = samples.length;
  final data = ByteData(44 + n * 2);

  void tag(int off, String s) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 36 + n * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // ukuran chunk fmt
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sr, Endian.little); // sample rate
  data.setUint32(28, sr * 2, Endian.little); // byte per detik
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bit per sample
  tag(36, 'data');
  data.setUint32(40, n * 2, Endian.little);

  for (var i = 0; i < n; i++) {
    var v = (samples[i] * gain * 32767).round();
    if (v > 32767) v = 32767;
    if (v < -32768) v = -32768;
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}

// ─────────────────────────────────────────────────────────────
// SYNTH DASAR
// ─────────────────────────────────────────────────────────────
double midiFreq(num m) => 440.0 * pow(2, (m - 69) / 12.0);

/// Envelope sederhana: attack cepat, decay lembut, release di akhir nada.
double envAt(double t, double dur) {
  if (t < 0 || t > dur) return 0;
  final attack = (dur * 0.08).clamp(0.001, 0.02);
  final release = (dur * 0.35).clamp(0.02, 0.12);
  var e = t < attack ? t / attack : 1.0;
  final relStart = dur - release;
  if (t > relStart) e *= ((dur - t) / release).clamp(0, 1);
  return e * (0.55 + 0.45 * exp(-t * 5));
}

/// Menambahkan satu nada ke buffer. Indeks yang lewat akhir buffer dibungkus
/// ke awal supaya loop musik menyambung mulus.
void addTone(
  List<double> buf,
  double start,
  double dur,
  double freq, {
  String wave = 'square',
  double gain = .3,
  double duty = .5,
}) {
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (dur * sr).round();
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    double w;
    switch (wave) {
      case 'tri':
        w = 4 * (((phase + .25) % 1) - .5).abs() - 1;
      case 'saw':
        w = 2 * (phase % 1) - 1;
      default: // square / pulse
        w = (phase % 1) < duty ? 1.0 : -1.0;
    }
    phase += freq / sr;
    final idx = (s0 + i) % total;
    buf[idx] += w * envAt(i / sr, dur) * gain;
  }
}

/// Ledakan noise pendek (untuk perkusi ringan).
void addNoise(List<double> buf, double start, double dur, double gain,
    {double decay = 30, int seed = 1}) {
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (dur * sr).round();
  final rnd = Random(seed);
  var prev = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final w = rnd.nextDouble() * 2 - 1;
    final hp = w - prev; // pembedaan = penekanan frekuensi tinggi
    prev = w;
    final idx = (s0 + i) % total;
    buf[idx] += hp * exp(-t * decay) * gain;
  }
}

// ─────────────────────────────────────────────────────────────
// SINTESIS GAYA MAHJONG
// ─────────────────────────────────────────────────────────────

/// Ketukan kepingan kayu ala mahjong: transien noise + resonansi kayu
/// memudar cepat. Dipakai untuk klik, ketuk ritmis, dan efek place.
void addClack(List<double> buf, double start,
    {double gain = .5, double freq = 2600, double decay = 85, int seed = 21}) {
  addNoise(buf, start, .014, gain * .45, decay: 170, seed: seed);
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (.07 * sr).round();
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final sig = sin(2 * pi * freq * t) * .55 +
        sin(2 * pi * freq * 1.58 * t) * .30 +
        sin(2 * pi * freq * 2.41 * t) * .18;
    final idx = (s0 + i) % total;
    buf[idx] += sig * exp(-t * decay) * gain;
  }
}

/// Petikan dawai Karplus-Strong — warna kecapi/koto/zheng untuk melodi
/// dan arpeggio musik latar.
void addPluck(
  List<double> buf,
  double start,
  double dur,
  double freq, {
  double gain = .3,
  double damp = .996,
  int seed = 7,
}) {
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (dur * sr).round();
  final period = (sr / freq).round();
  if (period < 4 || n <= 0) return;
  final rnd = Random(seed);
  final line = List<double>.filled(period, 0);
  for (var i = 0; i < period; i++) {
    line[i] = rnd.nextDouble() * 2 - 1;
  }
  var idx = 0;
  for (var i = 0; i < n; i++) {
    final out = line[idx];
    final nxt = line[(idx + 1) % period];
    line[idx] = damp * .5 * (out + nxt); // redaman + lowpass alami
    idx = (idx + 1) % period;
    final t = i / sr;
    final atk = i < sr * .002 ? i / (sr * .002) : 1.0;
    final env = exp(-t * 3.2 / dur) * atk;
    final o = (s0 + i) % total;
    buf[o] += out * env * gain;
  }
}

/// Gong kemenangan: partikel inharmonis memudar + serangan noise.
void addGong(List<double> buf, double start, double dur,
    {double gain = .3, double base = 190}) {
  const ratios = [1.0, 1.47, 2.02, 2.73, 3.51, 4.42];
  const level = [.50, .40, .32, .25, .18, .12];
  const decayK = [1.4, 1.9, 2.5, 3.2, 4.0, 5.0];
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (dur * sr).round();
  addNoise(buf, start, .04, gain * .35, decay: 70, seed: 13);
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    var sig = 0.0;
    for (var k = 0; k < ratios.length; k++) {
      sig += sin(2 * pi * base * ratios[k] * t) *
          level[k] *
          exp(-t * decayK[k] / dur * 3.0);
    }
    final atk = i < sr * .004 ? i / (sr * .004) : 1.0;
    final idx = (s0 + i) % total;
    buf[idx] += sig * gain * atk;
  }
}

/// Taiko: drum rendah penuh (gemuruh kain/bedug).
void addTaiko(List<double> buf, double start, {double gain = .4}) {
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (.28 * sr).round();
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final f = 130 * exp(-t * 16) + 55; // sapuan 130 → 55 Hz
    phase += f / sr;
    final idx = (s0 + i) % total;
    buf[idx] += sin(2 * pi * phase) * exp(-t * 11) * gain;
  }
  addNoise(buf, start, .02, gain * .25, decay: 220, seed: 31);
}

/// Desis gerakan ubin (shuffle): noise berpita sempit dengan envelope lonceng.
void addSwish(List<double> buf, double start, {double gain = .1, int seed = 41}) {
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (.12 * sr).round();
  final rnd = Random(seed);
  var hpPrev = 0.0;
  var lp = 0.0;
  for (var i = 0; i < n; i++) {
    final w = rnd.nextDouble() * 2 - 1;
    final hp = w - hpPrev;
    hpPrev = w;
    lp += .3 * (hp - lp); // lowpass lembut → desis halus
    final env = sin(pi * (i + 1) / n);
    final idx = (s0 + i) % total;
    buf[idx] += lp * env * gain;
  }
}

/// Nada dasar (pad) panjang dengan vibrato halus — kehangatan di latar.
void addPad(List<double> buf, double start, double dur, double freq,
    {double gain = .05}) {
  final total = buf.length;
  final s0 = (start * sr).round();
  final n = (dur * sr).round();
  final attack = (dur * .25).clamp(0.05, 0.4);
  final release = dur * .35;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final vib = 1 + .004 * sin(2 * pi * 5.2 * t);
    var e = t < attack ? t / attack : 1.0;
    if (t > dur - release) e *= ((dur - t) / release).clamp(0.0, 1.0);
    final sig = sin(2 * pi * freq * vib * t) + .3 * sin(2 * pi * freq * 2 * t);
    final idx = (s0 + i) % total;
    buf[idx] += sig * e * gain;
  }
}

// ─────────────────────────────────────────────────────────────
// MUSIK LATAR — 8 bar pentatonik C, loop mulus, 120 BPM
// Progresi C - Am - F - G; instrumen: koto (petik), taiko,
// ketukan kepingan, desis shuffle ubin, pad lembut.
// ─────────────────────────────────────────────────────────────
List<double> makeBgm() {
  const bpm = 120.0;
  const beat = 60.0 / bpm; // 0.5 dtk
  const bars = 8;
  final barLen = beat * 4; // 2 dtk
  final buf = List<double>.filled((bars * barLen * sr).round(), 0);

  final roots = [48, 45, 41, 43]; // C3 A2 F2 G2
  final chords = <List<int>>[
    [60, 64, 67], // C  — C E G
    [57, 60, 64], // Am — A C E
    [57, 60, 65], // F  — A C F
    [55, 62, 64], // G  — G D E
  ];

  // Melodi koto per bar (pentatonik: C D E G A), [nada, panjang (ketuk)]
  final melody = <List<num>>[
    [76, .5, 79, .5, 81, 1, 79, 1, 76, 1], // E G A G E
    [74, .5, 76, .5, 79, 1, 76, 1, 74, 1], // D E G E D
    [72, .5, 74, .5, 76, 1, 79, 2], // C D E — G
    [81, .5, 79, .5, 76, 1, 74, 2], // A G E — D
    [84, .5, 86, .5, 88, 1, 86, 1, 84, 1], // C D E D C (oktaf atas)
    [81, .5, 84, .5, 81, 1, 79, 1, 76, 1], // A C A G E
    [79, .5, 81, .5, 84, 1, 81, 1, 79, 1], // G A C A G
    [79, 1, 76, 1, 74, .5, 76, .5, 79, 1], // G E D E G (kembali ke loop)
  ];

  const bassPat = [0, 0, 12, 0, 0, 0, 12, 0];

  for (var bar = 0; bar < bars; bar++) {
    final t0 = bar * barLen;
    final root = roots[bar % 4];
    final chord = chords[bar % 4];

    // Bass — pola ketuk-delapan (tri lembut)
    for (var e = 0; e < 8; e++) {
      addTone(
        buf,
        t0 + e * beat / 2,
        beat / 2 * .9,
        midiFreq(root + bassPat[e]),
        wave: 'tri',
        gain: .30,
      );
    }

    // Arpeggio koto 8-nota (petik dawai)
    final arp = [chord[0], chord[1], chord[2], chord[1]];
    for (var s = 0; s < 8; s++) {
      addPluck(
        buf,
        t0 + s * beat / 2,
        beat * .8,
        midiFreq(arp[s % 4]),
        gain: .13,
        seed: 100 + bar * 8 + s,
      );
    }

    // Melodi utama koto
    var off = 0.0;
    final m = melody[bar];
    for (var i = 0; i < m.length; i += 2) {
      final d = m[i + 1].toDouble() * beat;
      addPluck(
        buf,
        t0 + off,
        d * .95,
        midiFreq(m[i].toDouble()),
        gain: .30,
        seed: 200 + bar * 7 + i,
      );
      off += d;
    }

    // Pad dasar + kehangatan
    addPad(buf, t0, barLen, midiFreq(root + 12), gain: .05);

    // Taiko pada ketukan 1 dan 3
    addTaiko(buf, t0, gain: .40);
    addTaiko(buf, t0 + 2 * beat, gain: .36);

    // Ketukan kepingan mahjong pada offbeat (tik-tik)
    for (var e = 1; e < 8; e += 2) {
      addClack(
        buf,
        t0 + e * beat / 2,
        gain: .15,
        freq: e % 4 == 1 ? 2700 : 3300,
        seed: 60 + e + bar,
      );
    }

    // Desis shuffle ubin pada ketukan 2 dan 4
    addSwish(buf, t0 + beat, gain: .09, seed: 70 + bar);
    addSwish(buf, t0 + 3 * beat, gain: .08, seed: 90 + bar);
  }
  return buf;
}

// ─────────────────────────────────────────────────────────────
// EFEK SUARA
// ─────────────────────────────────────────────────────────────

/// Klik kepingan: dua ketukan kayu cepat ("tik-tik").
List<double> makeClick() {
  final buf = List<double>.filled((.16 * sr).round(), 0);
  addClack(buf, 0, gain: .55, freq: 2900, decay: 95, seed: 21);
  addClack(buf, .055, gain: .48, freq: 3400, decay: 105, seed: 22);
  return buf;
}

/// Kepingan diletakkan: ketukan keras + badan meja rendah + sentuhan kedua.
List<double> makePlace() {
  final buf = List<double>.filled((.30 * sr).round(), 0);
  addClack(buf, 0, gain: .60, freq: 2300, decay: 70, seed: 5);
  addClack(buf, .045, gain: .22, freq: 1500, decay: 55, seed: 6);
  // badan meja: dengung rendah memudar
  final n = buf.length;
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final f = 170 * exp(-t * 14) + 70;
    phase += f / sr;
    buf[i] += sin(2 * pi * phase) * exp(-t * 11) * .55;
  }
  return buf;
}

/// Kemenangan: gong + lari nada pentatonik naik + akor penutup koto.
List<double> makeWin() {
  const dur = 1.7;
  final buf = List<double>.filled((dur * sr).round(), 0);
  addGong(buf, 0, 1.5, gain: .36, base: 196);
  const seq = [72, 74, 76, 79, 81, 84]; // C D E G A C
  const step = .07;
  for (var i = 0; i < seq.length; i++) {
    addPluck(buf, .04 + i * step, .7, midiFreq(seq[i]),
        gain: .34, seed: 11 + i);
  }
  final chordAt = .04 + seq.length * step + .05;
  for (final m in [72, 76, 79, 84]) {
    addPluck(buf, chordAt, 1.0, midiFreq(m), gain: .24, seed: 30 + m);
  }
  addPluck(buf, .5, 1.1, midiFreq(88), gain: .28, seed: 99); // kilau akhir
  return buf;
}

/// Gagal: kepingan jatuh (thud) + nada koto turun A-F-D.
List<double> makeFail() {
  const dur = .9;
  final buf = List<double>.filled((dur * sr).round(), 0);
  addClack(buf, 0, gain: .50, freq: 1500, decay: 60, seed: 17);
  // thud rendah
  final n = buf.length;
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final f = 140 * exp(-t * 10) + 60;
    phase += f / sr;
    buf[i] += sin(2 * pi * phase) * exp(-t * 7) * .5;
  }
  const seq = [69, 65, 62]; // A4 F4 D4 — turun
  const at = [0.0, .18, .36];
  for (var i = 0; i < seq.length; i++) {
    addPluck(buf, at[i], .5, midiFreq(seq[i]), gain: .30, seed: 51 + i);
  }
  return buf;
}
