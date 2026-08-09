import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/* ================= الثيم (ألوان زاجل + radius = 0.625rem زي المشروع المرفوع) ================= */
class T {
  static const primary = Color(0xFF6750C4), dark = Color(0xFF4B32A8), light = Color(0xFF9B86E4),
      lighter = Color(0xFFC4B8F0), bg = Color(0xFFF5F5F9), border = Color(0xFFE4E4EC),
      grey = Color(0xFF8A8A94), green = Color(0xFF2E9E5B), red = Color(0xFFD64545),
      orange = Color(0xFFB9770E), yellow = Color(0xFFE7C11A);
  static const r = 10.0;
}

/* ================= النماذج ================= */
enum OS { delivered, inProgress, canceled, onTheRoad }

OS osFrom(String s) => OS.values.firstWhere((e) => e.name == s, orElse: () => OS.inProgress);

extension OSX on OS {
  String get label => ['Delivered', 'IN Progress', 'Canceled', 'On The Road'][index];
  Color get fg => [T.green, const Color(0xFF555560), T.red, T.orange][index];
  Color get bg => [const Color(0xFFE6F6EC), const Color(0xFFEDEDF2), const Color(0xFFFBE9E9), const Color(0xFFFDF3E1)][index];
}

class Order {
  final String id, customer, from, to, driver, date, day, audio;
  final double total;
  final OS status;
  const Order({required this.id, required this.customer, required this.status, required this.from,
      required this.to, required this.driver, required this.date, this.day = '', this.audio = '', this.total = 0});
  Map<String, dynamic> toMap() => {'id': id, 'customer': customer, 'status': status.name, 'from': from,
    'to': to, 'driver': driver, 'date': date, 'day': day, 'audio': audio, 'total': total};
  factory Order.fromMap(Map m) => Order(id: m['id'] ?? '', customer: m['customer'] ?? '',
      status: osFrom(m['status'] ?? ''), from: m['from'] ?? '', to: m['to'] ?? '', driver: m['driver'] ?? '',
      date: m['date'] ?? '', day: m['day'] ?? '', audio: m['audio'] ?? '', total: (m['total'] as num? ?? 0).toDouble());
}

class Driver {
  final String id, name, phone, nid, start;
  final int rate;
  final bool active, shiftOpen;
  final double percentage;
  const Driver({required this.id, required this.name, required this.phone, required this.nid,
      required this.start, required this.rate, this.active = true, this.shiftOpen = true, this.percentage = 15});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'phone': phone, 'nid': nid, 'start': start,
    'rate': rate, 'active': active, 'shiftOpen': shiftOpen, 'percentage': percentage};
  factory Driver.fromMap(Map m) => Driver(id: m['id'] ?? '', name: m['name'] ?? '', phone: m['phone'] ?? '',
      nid: m['nid'] ?? '', start: m['start'] ?? '', rate: m['rate'] as int? ?? 5,
      active: m['active'] as bool? ?? true, shiftOpen: m['shiftOpen'] as bool? ?? true,
      percentage: (m['percentage'] as num? ?? 15).toDouble());
}

class Settl {
  final String id, driverId, driverName, day, closedAt;
  final double total, company, driverShare, percentage;
  const Settl({required this.id, required this.driverId, required this.driverName, required this.day,
      required this.closedAt, required this.total, required this.company, required this.driverShare, required this.percentage});
  Map<String, dynamic> toMap() => {'id': id, 'driverId': driverId, 'driverName': driverName, 'day': day,
    'closedAt': closedAt, 'total': total, 'company': company, 'driverShare': driverShare, 'percentage': percentage};
  factory Settl.fromMap(Map m) => Settl(id: m['id'] ?? '', driverId: m['driverId'] ?? '', driverName: m['driverName'] ?? '',
      day: m['day'] ?? '', closedAt: m['closedAt'] ?? '', total: (m['total'] as num? ?? 0).toDouble(),
      company: (m['company'] as num? ?? 0).toDouble(), driverShare: (m['driverShare'] as num? ?? 0).toDouble(),
      percentage: (m['percentage'] as num? ?? 0).toDouble());
}

/* ================= المخزن (Hive — أوفلاين) ================= */
class Store {
  static late Box _o, _d, _s, _st;
  static String today() => DateTime.now().toIso8601String().substring(0, 10);

  static Future<void> init() async {
    await Hive.initFlutter();
    _o = await Hive.openBox('o'); _d = await Hive.openBox('d'); _s = await Hive.openBox('s'); _st = await Hive.openBox('st');
    _seed();
  }

  static void _seed() {
    final t = today();
    if (_o.isEmpty) {
      const L = [
        Order(id: 'o1', customer: 'Hot creep', status: OS.delivered, from: 'Restaurant', to: 'Fox Square', driver: 'MAGDY MAHMOUD', date: '12:15 AM', total: 250),
        Order(id: 'o2', customer: 'Darb El3omdaa', status: OS.delivered, from: 'Restaurant', to: 'Elsalam', driver: 'MAGDY MAHMOUD', date: '12:15 AM', total: 350),
        Order(id: 'o3', customer: 'Bazz', status: OS.canceled, from: 'Restaurant', to: 'Garden city', driver: 'darsh', date: '12:15 AM', total: 180),
        Order(id: 'o4', customer: '7assan', status: OS.onTheRoad, from: 'elshikh zaied', to: 'ELmostakbal', driver: 'ahmed', date: '12:15 AM', total: 220),
        Order(id: 'o5', customer: 'Layers', status: OS.onTheRoad, from: 'Restaurant', to: '3oraby', driver: 'omar', date: '12:15 AM', total: 140),
        Order(id: 'o6', customer: 'Quotient', status: OS.delivered, from: 'Restaurant', to: 'Elhorrya st', driver: 'MAGDY MAHMOUD', date: '12:15 AM', total: 400),
        Order(id: 'o7', customer: 'Sisyphus', status: OS.delivered, from: 'Restaurant', to: 'ELtalatiny', driver: 'saleh', date: '12:15 AM', total: 300),
      ];
      for (var o in L) _o.put(o.id, o.toMap()..['day'] = t);
    }
    if (_d.isEmpty) {
      for (int i = 1; i <= 4; i++) _d.put('a$i', Driver(id: 'a$i', name: 'MAGDY MAHMOUD', phone: '0128525648', nid: '20185649852695262', start: '11/2/2025', rate: 5).toMap());
      for (int i = 1; i <= 4; i++) _d.put('f$i', Driver(id: 'f$i', name: 'MAGDY MAHMOUD', phone: '0128525648', nid: '20185649852695262', start: '11/2/2025', rate: 5, active: false, shiftOpen: false).toMap());
    }
    if (!_s.containsKey('data')) _s.put('data', {'adminName': 'Saleh', 'companyPercentage': '15', 'language': 'English'});
  }

  static void dailyReset() {
    final t = today();
    for (final d in drivers()) {
      if (!d.shiftOpen && !settl(d.id).any((x) => x.day == t)) {
        putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: true, shiftOpen: true, percentage: d.percentage));
      }
    }
  }

  static List<Order> orders() => _o.values.map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  static List<Driver> drivers() => _d.values.map((e) => Driver.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  static List<Settl> settl([String? id]) => _st.values.map((e) => Settl.fromMap(Map<String, dynamic>.from(e as Map)))
      .where((x) => id == null || x.driverId == id).toList()..sort((a, b) => b.id.compareTo(a.id));
  static Map<String, dynamic> settings() => Map<String, dynamic>.from(_s.get('data') as Map? ?? {});
  static void saveSettings(Map<String, dynamic> m) => _s.put('data', m);
  static void putOrder(Order o) => _o.put(o.id, o.toMap());
  static void delOrder(String id) => _o.delete(id);
  static void putDriver(Driver d) => _d.put(d.id, d.toMap());
  static void applyAll(double p) {
    for (final d in drivers()) putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: d.active, shiftOpen: d.shiftOpen, percentage: p));
    saveSettings(settings()..['companyPercentage'] = p.toStringAsFixed(0));
  }

  static double todayTotal(Driver d) => orders()
      .where((o) => o.driver == d.name && o.day == today() && o.status == OS.delivered)
      .fold(0.0, (a, o) => a + o.total);

  static Settl closeShift(Driver d) {
    final total = todayTotal(d), co = total * d.percentage / 100;
    final st = Settl(id: 's${DateTime.now().millisecondsSinceEpoch}', driverId: d.id, driverName: d.name,
        day: today(), closedAt: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        total: total, company: co, driverShare: total - co, percentage: d.percentage);
    _st.put(st.id, st.toMap());
    putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: false, shiftOpen: false, percentage: d.percentage));
    return st;
  }

  static List<Settl> closeAll() => [for (final d in drivers()) if (d.shiftOpen) closeShift(d)];
}

/* ================= الصوت (تسجيل + تشغيل) ================= */
class Audio_ {
  static final rec = AudioRecorder();
  static final pl = AudioPlayer();
  static final playing = ValueNotifier<String?>(null);
  static bool _r = false;
  static void _e() { if (!_r) { pl.onPlayerComplete.listen((_) => playing.value = null); _r = true; } }

  static Future<String?> start() async {
    _e();
    if (!await rec.hasPermission()) return null;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/zajil_audio')..createSync(recursive: true);
    final p = '${dir.path}/o_${DateTime.now().millisecondsSinceEpoch}.wav';
    await rec.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: p);
    return p;
  }

  static Future<String?> stop() => rec.stop();

  static Future<void> toggle(String p) async {
    _e();
    if (playing.value == p) { await pl.stop(); playing.value = null; }
    else { await pl.stop(); await pl.play(DeviceFileSource(p)); playing.value = p; }
  }
}

/* ================= التفريغ الأوفلاين (Whisper tiny — نموذج جنب الـ exe أو تحميل مرة واحدة) ================= */
class STT {
  static sherpa.OfflineRecognizer? _rec;
  static const _files = ['tokens.txt', 'encoder.onnx', 'decoder.onnx'];
  static const _urls = {
    'tokens.txt': 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main/tokens.txt',
    'encoder.onnx': 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main/encoder.onnx',
    'decoder.onnx': 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main/decoder.onnx',
  };

  static bool _complete(Directory d) => _files.every((f) => File('${d.path}/$f').existsSync());

  static Future<String> _dir(void Function(String) onP) async {
    final bundled = Directory('${File(Platform.resolvedExecutable).parent.path}/zajil_stt');
    if (_complete(bundled)) { onP('نموذج مرفق مع الجهاز ✔'); return bundled.path; }
    final base = await getApplicationDocumentsDirectory();
    final docs = Directory('${base.path}/zajil_stt');
    if (_complete(docs)) return docs.path;
    docs.createSync(recursive: true);
    for (final e in _urls.entries) {
      final f = File('${docs.path}/${e.key}');
      if (!f.existsSync()) {
        onP('تحميل ${e.key} (أول مرة بس)...');
        final r = await http.get(Uri.parse(e.value));
        if (r.statusCode != 200) throw 'فشل تحميل ${e.key}';
        f.writeAsBytesSync(r.bodyBytes);
      }
    }
    return docs.path;
  }

  static Future<void> init(void Function(String) onP) async {
    if (_rec != null) return;
    final dir = await _dir(onP);
    onP('تجهيز المحرك...');
      _rec = sherpa.OfflineRecognizer(sherpa.OfflineRecognizerConfig(
        feat: sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
        model: sherpa.OfflineModelConfig(tokens: '$dir/tokens.txt', numThreads: 2,
            whisper: sherpa.OfflineWhisperModelConfig(encoder: '$dir/encoder.onnx',
                decoder: '$dir/decoder.onnx', language: 'ar', task: 'transcribe'))));
  }

  static Future<String> run(File wav) async {
    await init((_) {});
    final bytes = await wav.readAsBytes();
    final b = ByteData.sublistView(bytes);
    int off = 12, ch = 1, dOff = -1, dLen = 0;
    while (off + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(off, off + 4));
      final sz = b.getUint32(off + 4, Endian.little);
      final body = off + 8;
      if (id == 'fmt ') ch = b.getUint16(body + 2, Endian.little);
      else if (id == 'data') { dOff = body; dLen = sz; }
      off = body + sz + (sz.isOdd ? 1 : 0);
    }
    if (dOff < 0) throw 'ملف صوت غير مدعوم';
    final n = (dLen ~/ 2) ~/ ch;
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      int x = 0;
      for (int c = 0; c < ch; c++) x += b.getInt16(dOff + (i * ch + c) * 2, Endian.little);
      s[i] = x / ch / 32768;
    }
    final st = _rec!.createStream();
    st.acceptWaveform(samples: s, sampleRate: 16000);
    _rec!.decode(st);
    return _rec!.getResult(st).text.trim();
  }
}

/* ================= ويدجتس الرسم ================= */
class Rings extends StatelessWidget {
  final double size;
  final String label;
  const Rings(this.label, {super.key, this.size = 200});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
      child: CustomPaint(painter: _RP(),
          child: Center(child: Text(label, style: TextStyle(fontSize: size * .15, fontWeight: FontWeight.w700)))));
}

class _RP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ce = s.center(Offset.zero);
    final b = s.shortestSide / 2;
    for (final f in [1.0, .8, .6]) {
      c.drawArc(Rect.fromCircle(center: ce, radius: b * f - b * .08), 0, 2 * math.pi, false,
          Paint()..color = const Color(0xFFE9E9F0)..style = PaintingStyle.stroke..strokeWidth = b * .16);
    }
    const sp = [[T.dark, 1.0, .88], [T.light, .8, .72], [T.lighter, .6, .55]];
    for (final x in sp) {
      c.drawArc(Rect.fromCircle(center: ce, radius: b * (x[1] as double) - b * .08), -math.pi / 2,
          2 * math.pi * (x[2] as double), false,
          Paint()..color = x[0] as Color..style = PaintingStyle.stroke..strokeWidth = b * .16..strokeCap = StrokeCap.round);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Spark extends StatelessWidget {
  final bool up;
  final Color? color;
  const Spark({super.key, this.up = true, this.color});
  @override
  Widget build(BuildContext context) {
    final pts = up ? const [.85, .6, .72, .45, .55, .3, .42, .12] : const [.15, .35, .28, .5, .45, .62, .56, .8];
    return CustomPaint(size: const Size(64, 34), painter: _SP(pts, color ?? (up ? T.green : T.red)));
  }
}

class _SP extends CustomPainter {
  final List<double> p;
  final Color c;
  _SP(this.p, this.c);
  @override
  void paint(Canvas ca, Size s) {
    final st = s.width / 7;
    final o = [for (var i = 0; i < 8; i++) Offset(i * st, p[i] * s.height)];
    final pa = Path()..moveTo(o[0].dx, o[0].dy);
    for (var i = 1; i < 8; i++) { final m = (o[i - 1] + o[i]) / 2; pa.quadraticBezierTo(o[i - 1].dx, o[i - 1].dy, m.dx, m.dy); }
    pa.lineTo(o[7].dx, o[7].dy);
    ca.drawPath(Path.from(pa)..lineTo(s.width, s.height)..lineTo(0, s.height)..close(), Paint()..color = c.withOpacity(.12));
    ca.drawPath(pa, Paint()..color = c..strokeWidth = 2..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArcRing extends StatelessWidget {
  final double size, th;
  final List<Color> colors;
  final List<double> fracs;
  final Widget? center;
  const ArcRing({super.key, required this.size, required this.th, required this.colors, required this.fracs, this.center});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
      child: CustomPaint(painter: _ArcP(colors, fracs, th), child: Center(child: center)));
}

class _ArcP extends CustomPainter {
  final List<Color> colors;
  final List<double> fracs;
  final double th;
  _ArcP(this.colors, this.fracs, this.th);
  @override
  void paint(Canvas c, Size s) {
    final ce = s.center(Offset.zero);
    final r = s.shortestSide / 2 - th / 2;
    double start = -math.pi / 2;
    for (int i = 0; i < colors.length; i++) {
      c.drawArc(Rect.fromCircle(center: ce, radius: r), start, 2 * math.pi * fracs[i] - 0.04, false,
          Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = th);
      start += 2 * math.pi * fracs[i];
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomersLineChart extends StatelessWidget {
  const CustomersLineChart({super.key});
  static const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  @override
  Widget build(BuildContext context) => LineChart(LineChartData(
      minX: 0, maxX: 11, minY: 0, maxY: 80,
      gridData: FlGridData(show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: T.border.withOpacity(.6), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 18, getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i > 11) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(months[i], style: const TextStyle(fontSize: 10, color: T.grey)));
        })),
      ),
      lineBarsData: [
        _bar(const [52, 54, 53, 56, 58, 57, 60, 62, 61, 64, 66, 68], const Color(0xFF9B86E4), true),
        _bar(const [38, 39, 40, 41, 40, 42, 43, 44, 45, 46, 47, 48], const Color(0xFFC4B8F0), false),
        _bar(const [18, 19, 18, 20, 21, 20, 22, 23, 22, 24, 26, 27], const Color(0xFF3F2B96), false),
      ]));
  LineChartBarData _bar(List<double> v, Color c, bool fill) => LineChartBarData(
      spots: [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i])],
      isCurved: true, preventCurveOverShooting: true, color: c, barWidth: 2,
      dotData: FlDotData(show: false), belowBarData: BarAreaData(show: fill, color: c.withOpacity(.14)));
}

class TotalOrdersAreaChart extends StatelessWidget {
  const TotalOrdersAreaChart({super.key});
  static const vals = <double>[90000, 30000, 28000, 42000, 50000, 55000, 60000, 90000, 140000, 35000, 20000, 30000, 60000];
  @override
  Widget build(BuildContext context) => LineChart(LineChartData(
      minX: 0, maxX: vals.length - 1, minY: 0, maxY: 150000,
      gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 58, interval: 50000,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(2), style: const TextStyle(fontSize: 9, color: T.grey)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 18, getTitlesWidget: (v, _) {
          const l = {0: 'Oct', 4: 'Nov', 8: 'Dec', 12: 'Janv'};
          final t = l[v.toInt()];
          if (t == null) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(t, style: TextStyle(fontSize: 10, color: t == 'Dec' ? const Color(0xFFB03BC7) : T.grey)));
        })),
      ),
      extraLinesData: ExtraLinesData(verticalLines: [VerticalLine(x: 8, color: T.primary.withOpacity(.35), strokeWidth: 1)]),
      lineBarsData: [LineChartBarData(
          spots: [for (var i = 0; i < vals.length; i++) FlSpot(i.toDouble(), vals[i])],
          isCurved: true, preventCurveOverShooting: true, color: const Color(0xFFA43BC4), barWidth: 2,
          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => i == 8
              ? FlDotCirclePainter(radius: 4, color: T.dark)
              : FlDotCirclePainter(radius: 0, color: Colors.transparent)),
          belowBarData: BarAreaData(show: true, gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x99A43BC4), Color(0x0AA43BC4)])))]));
}

/* ================= كروت وعناصر عامة ================= */
class StatCard extends StatelessWidget {
  final String title, value;
  final String? delta;
  final bool up;
  final String vs;
  final Color? sc;
  final bool spark;
  const StatCard({super.key, required this.title, required this.value, this.delta,
      this.up = true, this.vs = 'vs last month', this.sc, this.spark = true});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(T.r),
          border: Border.all(color: T.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const Icon(Icons.more_vert, size: 16, color: T.grey)]),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        const Spacer(),
        Row(children: [
          if (delta != null) ...[
            Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: sc ?? (up ? T.green : T.red)),
            Text(' ${delta!} ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc ?? (up ? T.green : T.red))),
          ],
          Expanded(child: Text(vs, style: const TextStyle(fontSize: 11, color: T.grey))),
          if (spark) Spark(up: up, color: sc),
        ]),
      ]));
}

class PlainCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const PlainCard({super.key, this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(T.r), border: Border.all(color: T.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null) Row(children: [Expanded(child: Text(title!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          const Icon(Icons.more_vert, size: 16, color: T.grey)]),
        if (title != null) const SizedBox(height: 10),
        Expanded(child: child),
      ]));
}

class DriverCard extends StatelessWidget {
  final Driver d;
  final VoidCallback? open, close;
  const DriverCard({super.key, required this.d, this.open, this.close});
  @override
  Widget build(BuildContext context) {
    final on = d.active && d.shiftOpen;
    return GestureDetector(onTap: open,
        child: Container(constraints: const BoxConstraints(minWidth: 160),
            decoration: BoxDecoration(color: on ? T.primary : const Color(0xFF0D0D0F),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 5))]),
            child: Column(children: [
              const SizedBox(height: 12),
              Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.person, size: 74, color: Color(0xFF33333A))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(d.name.toUpperCase(), overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                const SizedBox(width: 4),
                Icon(Icons.bolt, size: 14, color: on ? const Color(0xFF38EF7D) : const Color(0xFF9A9AA2)),
              ]),
              const SizedBox(height: 8),
              const Text('RATE', style: TextStyle(fontSize: 10, color: Colors.white70)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                for (int i = 0; i < 5; i++) Icon(Icons.star, size: 16, color: i < d.rate ? T.yellow : Colors.white24)]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('الشركة ${d.percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                if (on && close != null) IconButton(onPressed: close, tooltip: 'قفل الشيفت وتسوية الحساب',
                    icon: const Icon(Icons.lock_clock, size: 18, color: T.yellow)),
                if (!on) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: T.red.withOpacity(.85), borderRadius: BorderRadius.circular(4)),
                    child: const Text('SHIFT CLOSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white))),
              ]),
              const SizedBox(height: 10),
            ])));
  }
}

class OTable extends StatelessWidget {
  final List<Order> list;
  final bool edit;
  final Set<String> sel;
  final Function(Order)? tog, del, edt;
  const OTable({super.key, required this.list, this.edit = false, this.sel = const {}, this.tog, this.del, this.edt});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(T.r), border: Border.all(color: T.border)),
      child: Column(children: [_h(), for (int i = 0; i < list.length; i++) _r(i)]));

  Widget _h() => Container(padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: T.border))),
      child: Row(children: [
        const SizedBox(width: 40, child: Icon(Icons.remove_circle_outline, size: 15, color: T.primary)),
        const Expanded(flex: 3, child: Text('Customer ↓', style: TextStyle(fontSize: 11, color: Color(0xFF555560)))),
        for (final t in ['Status', 'From', 'To', 'Driver', 'Date', 'Total'])
          Expanded(flex: 2, child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF555560)))),
        const SizedBox(width: 110),
      ]));

  Widget _r(int i) {
    final o = list[i];
    final s = sel.contains(o.id);
    return Container(color: i.isEven ? Colors.white : const Color(0xFFF7F7FB),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(children: [
          SizedBox(width: 40, child: GestureDetector(onTap: () => tog?.call(o),
              child: Container(width: 18, height: 18,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: s ? T.primary : const Color(0xFFC9C9D4), width: 1.4)),
                  child: s ? const Icon(Icons.check, size: 13, color: T.primary) : null))),
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(radius: 15, backgroundColor: T.primary,
                child: Text(o.customer.isNotEmpty ? o.customer[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, color: Colors.white))),
            const SizedBox(width: 8),
            Flexible(child: Text(o.customer, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ])),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: o.status.bg, borderRadius: BorderRadius.circular(4)),
              child: Text(o.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: o.status.fg)))),
          Expanded(flex: 2, child: Text(o.from, style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text(o.to, style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text(o.driver, style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text(o.date, style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text('${o.total.toStringAsFixed(0)} EGP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          SizedBox(width: 110, child: Row(children: [
            if (o.audio.isNotEmpty) ValueListenableBuilder<String?>(valueListenable: Audio_.playing,
                builder: (_, p, __) => IconButton(onPressed: () => Audio_.toggle(o.audio),
                    icon: Icon(p == o.audio ? Icons.stop_circle_outlined : Icons.volume_up, size: 18,
                        color: p == o.audio ? T.red : T.primary))),
            IconButton(onPressed: () => del?.call(o), icon: const Icon(Icons.delete_outline, size: 17, color: Color(0xFF77777F))),
            if (edit) IconButton(onPressed: () => edt?.call(o), icon: const Icon(Icons.mode_edit_outline, size: 16, color: Color(0xFF77777F))),
          ])),
        ]));
  }
}

class Sidebar extends StatelessWidget {
  final int sel;
  final ValueChanged<int> on;
  final Widget? extra;
  final VoidCallback onLogout;
  const Sidebar({super.key, required this.sel, required this.on, required this.onLogout, this.extra});
  static const it = [
    ['Dashboard', Icons.bar_chart, 0],
    ['Drivers', Icons.layers, 1],
    ['Orders', Icons.fact_check_outlined, 2],
    ['Statics', Icons.flag_outlined, 3],
    ['Settings', Icons.settings, 4],
  ];
  @override
  Widget build(BuildContext context) => Container(width: 210, padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(children: [
        for (final x in it)
          Container(margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: sel == x[2] as int ? T.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]),
              child: InkWell(borderRadius: BorderRadius.circular(8), onTap: () => on(x[2] as int),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        Icon(x[1] as IconData, size: 18, color: sel == x[2] as int ? Colors.white : const Color(0xFF555560)),
                        const SizedBox(width: 10),
                        Text(x[0] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: sel == x[2] as int ? Colors.white : const Color(0xFF202028))),
                      ])))),
        const Spacer(),
        if (extra != null) extra!,
        const Divider(),
        Row(children: [
          const CircleAvatar(radius: 15, backgroundColor: Color(0xFFE4D9F7), child: Icon(Icons.person, size: 18, color: T.primary)),
          const SizedBox(width: 8),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Saleh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Text('Saleh@admin.com', style: TextStyle(fontSize: 10, color: T.grey)),
          ])),
          IconButton(onPressed: onLogout, icon: const Icon(Icons.logout, size: 18)),
        ]),
      ]));
}

Future<bool> confirm(BuildContext c, String m) async =>
    (await showDialog<bool>(context: c, builder: (c2) => AlertDialog(
        title: const Text('تأكيد'), content: Text(m),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c2, false), child: const Text('لا')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: T.primary),
              onPressed: () => Navigator.pop(c2, true), child: const Text('أيوة')),
        ]))) ?? false;

/* ================= حوار إضافة/تعديل أوردر (بالصوت + التفريغ) ================= */
Future<void> showOrderDialog(BuildContext context, [Order? existing]) =>
    showDialog(context: context, builder: (_) => _OrderDialog(existing: existing));

class _OrderDialog extends StatefulWidget {
  final Order? existing;
  const _OrderDialog({this.existing});
  @override
  State<_OrderDialog> createState() => _ODS();
}

class _ODS extends State<_OrderDialog> {
  late final TextEditingController customerC = TextEditingController(text: widget.existing?.customer);
  late final TextEditingController fromC = TextEditingController(text: widget.existing?.from);
  late final TextEditingController toC = TextEditingController(text: widget.existing?.to);
  late final TextEditingController driverC = TextEditingController(text: widget.existing?.driver);
  late final TextEditingController totalC = TextEditingController(text: widget.existing == null ? '' : widget.existing!.total.toStringAsFixed(0));
  final TextEditingController noteC = TextEditingController();
  late OS status = widget.existing?.status ?? OS.inProgress;
  late String? audioId = (widget.existing?.audio.isNotEmpty ?? false) ? widget.existing!.audio : null;
  bool rec = false, busy = false;
  int sec = 0;
  int timer = 0;

  @override
  void dispose() {
    if (timer != 0) { /* interval ملغى في stop */ }
    super.dispose();
  }

  Future<void> toggleMic() async {
    if (!rec) {
      final p = await Audio_.start();
      if (p == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لازم السماح بالمايكروفون'))); return; }
      audioId = p;
      setState(() { rec = true; sec = 0; });
      Future.doWhile(() async {
        if (!rec) return false;
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) setState(() => sec++);
        return rec;
      });
    } else {
      setState(() { rec = false; busy = true; });
      final p = await Audio_.stop();
      if (p != null) audioId = p;
      try {
        final text = await STT.run(File(audioId!));
        if (mounted) {
          noteC.text = text;
          final cust = RegExp(r'(?:للعميل|عميل|customer)\s*[:：]?\s*(.+?)(?=\s+(?:من|الى|إلى|from|to)\b|\s*$)', caseSensitive: false).firstMatch(text);
          final fr = RegExp(r'(?:من|from)\s*[:：]?\s*(.+?)(?=\s+(?:الى|إلى|to|for)\b|\s*$)', caseSensitive: false).firstMatch(text);
          final t2 = RegExp(r'(?:الى|إلى|to|for)\s*[:：]?\s*(.+?)(?=\s+(?:من|from)\b|\s*$)', caseSensitive: false).firstMatch(text);
          setState(() {
            if (cust?.group(1) != null) customerC.text = cust!.group(1)!.trim();
            if (fr?.group(1) != null) fromC.text = fr!.group(1)!.trim();
            if (t2?.group(1) != null) toC.text = t2!.group(1)!.trim();
          });
          if (text.isEmpty) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('معرفناش نلتقط كلام واضح — قرّب من المايك')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التفريغ: $e')));
      }
      if (mounted) setState(() => busy = false);
    }
  }

  void save() {
    Store.putOrder(Order(
        id: widget.existing?.id ?? 'o${DateTime.now().millisecondsSinceEpoch}',
        customer: customerC.text.isEmpty ? 'New Customer' : customerC.text,
        status: status, from: fromC.text, to: toC.text,
        driver: driverC.text.isEmpty ? 'None' : driverC.text,
        date: widget.existing?.date ?? '12:15 AM',
        day: (widget.existing?.day.isEmpty ?? true) ? Store.today() : widget.existing!.day,
        audio: audioId ?? '', total: double.tryParse(totalC.text) ?? 0));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: Text(widget.existing == null ? 'Add New Order' : 'Edit Order'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF4F1FC), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              busy ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: T.primary)))
                : IconButton(onPressed: toggleMic, tooltip: 'اتكلّم وهو يملّي الأوردر',
                    icon: Icon(rec ? Icons.stop_circle : Icons.mic, color: rec ? T.red : T.primary)),
              Expanded(child: Text(
                  rec ? 'جارٍ التسجيل.. ${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')} ⏺'
                      : busy ? 'بنفرّغ الكلام ✍️' : 'دوس المايك وقول: عميل حسن من مطعم الشرق الى مدينة نصر',
                  style: const TextStyle(fontSize: 11))),
              if (audioId != null) IconButton(icon: const Icon(Icons.play_arrow, size: 20, color: T.primary),
                  onPressed: () => Audio_.toggle(audioId!)),
            ])),
        const SizedBox(height: 10),
        TextField(controller: noteC, maxLines: 2, decoration: const InputDecoration(labelText: 'النص المتعرّف عليه')),
        const SizedBox(height: 10),
        TextField(controller: customerC, decoration: const InputDecoration(labelText: 'Customer')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: fromC, decoration: const InputDecoration(labelText: 'From'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: toC, decoration: const InputDecoration(labelText: 'To'))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: driverC, decoration: const InputDecoration(labelText: 'Driver'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: totalC, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total (EGP)'))),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<OS>(value: status,
            items: [for (final s in OS.values) DropdownMenuItem(value: s, child: Text(s.label))],
            onChanged: (v) => setState(() => status = v!)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: T.primary), onPressed: save, child: const Text('Save')),
      ]);
}

Future<void> showDriverDialog(BuildContext context) {
  final name = TextEditingController(), phone = TextEditingController(), nid = TextEditingController();
  final pct = TextEditingController(text: Store.settings()['companyPercentage'] as String? ?? '15');
  int rate = 5;
  return showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      title: const Text('Add New Driver'),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 10),
        TextField(controller: nid, decoration: const InputDecoration(labelText: 'National ID')),
        const SizedBox(height: 10),
        TextField(controller: pct, decoration: const InputDecoration(labelText: 'Company % (نسبة الشركة)')),
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(value: rate,
            items: [for (int i = 1; i <= 5; i++) DropdownMenuItem(value: i, child: Text('$i ★'))],
            onChanged: (v) => setSt(() => rate = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: T.primary), onPressed: () {
          final id = 'd${DateTime.now().millisecondsSinceEpoch}';
          Store.putDriver(Driver(id: id, name: name.text.isEmpty ? 'NEW DRIVER' : name.text, phone: phone.text,
              nid: nid.text, start: Store.today(), rate: rate, active: true, shiftOpen: true,
              percentage: double.tryParse(pct.text) ?? 15));
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ])));
}

/* ================= الشاشات ================= */
class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LS();
}

class _LS extends State<LoginScreen> {
  final _n = TextEditingController(), _p = TextEditingController();
  void go() {
    if (_n.text.isEmpty || _p.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your name and password')));
      return;
    }
    Store.saveSettings(Store.settings()..['adminName'] = _n.text);
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Row(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Log in', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          const Text('Name*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(controller: _n, decoration: const InputDecoration(hintText: 'Enter your name')),
          const SizedBox(height: 16),
          const Text('Password*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(controller: _p, obscureText: true, decoration: const InputDecoration(hintText: 'Create a password')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: T.primary, elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: go, child: const Text('Log in', style: TextStyle(color: Colors.white)))),
        ])),
        const SizedBox(width: 90),
        Container(width: 300, height: 300,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [Color(0xFF7A1FA2), Color(0xFF5B1283)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: const Color(0xFF3E0B5C), width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 24, offset: const Offset(0, 10))]),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🕊️            🕊️', style: TextStyle(fontSize: 22)),
              SizedBox(height: 6),
              Text('زاجل', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: T.yellow)),
              Text('Z A J I L', style: TextStyle(fontSize: 16, letterSpacing: 4, color: T.yellow)),
              SizedBox(height: 10),
              Text('سرعة .. تسليم .. دقة', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ])),
      ])));
}

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});
  @override
  State<MainShell> createState() => _MS();
}

class _MS extends State<MainShell> {
  int page = 0;
  String? profileId;
  static const titles = ['Dashboard', 'Drivers', 'Orders', 'Statics', 'Settings'];
  @override
  Widget build(BuildContext context) => Scaffold(body: Column(children: [
        Container(height: 64, color: T.primary, alignment: Alignment.center,
            child: Text(page == 5 ? 'Profile' : titles[page],
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800))),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Sidebar(sel: page > 4 ? 1 : page, on: (i) => setState(() => page = i), onLogout: widget.onLogout,
              extra: (page == 1 || page == 2) ? _ring() : null),
          Expanded(child: _content()),
        ])),
      ]));

  Widget _ring() => Padding(padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(page == 1 ? 'Active now' : 'Orders Delivering Now',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          const Icon(Icons.more_vert, size: 14, color: T.grey),
        ]),
        const SizedBox(height: 12),
        const Center(child: Rings('25', size: 150)),
      ]));

  Widget _content() {
    switch (page) {
      case 0: return const DashboardScreen();
      case 1: return DriversScreen(onProfile: (id) => setState(() { profileId = id; page = 5; }));
      case 2: return const OrdersScreen();
      case 3: return const StaticsScreen();
      case 4: return const SettingsScreen();
      default: return DriverProfileScreen(id: profileId ?? 'a1', onBack: () => setState(() => page = 1));
    }
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DS();
}

class _DS extends State<DashboardScreen> {
  String q = '';
  final Set<String> sel = {};
  @override
  Widget build(BuildContext context) {
    final os = Store.orders().where((o) => o.customer.toLowerCase().contains(q.toLowerCase())).toList();
    final t = Store.today();
    final all = Store.orders();
    final inProg = all.where((o) => o.status == OS.inProgress || o.status == OS.onTheRoad).length;
    final profit = Store.settl().fold<double>(0, (a, e) => a + e.company);
    final cards = [
      const StatCard(title: 'Total customers', value: '3000', delta: '40%'),
      StatCard(title: 'Orders Today', value: '${all.where((o) => o.day == t).length}', delta: '10%', up: false),
      StatCard(title: 'in progress now', value: '$inProg', sc: const Color(0xFFDDEEDF)),
      const StatCard(title: 'Last Hour', value: '0', delta: '40%'),
      const StatCard(title: 'yesterday', value: '1,210', delta: '10%', up: false),
      const StatCard(title: 'this Week', value: '316', sc: Color(0xFFD64545), up: false),
      StatCard(title: 'Company Profit', value: profit.toStringAsFixed(0), delta: '40%'),
      StatCard(title: 'Active Drivers', value: '${Store.drivers().where((d) => d.active).length}', sc: const Color(0xFFE4F3E6)),
    ];
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 330, height: 280, child: PlainCard(title: 'Active now',
            child: Center(child: Rings('$inProg', size: 210)))),
        const SizedBox(width: 20),
        SizedBox(height: 280, child: Expanded(child: PlainCard(title: 'Total customers',
            child: Column(children: [
                 Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _lg(Color(0xFF9B86E4), '2021'), _lg(Color(0xFFC4B8F0), '2020'), _lg(Color(0xFF3F2B96), '2019'),
              ]),
            ])))),
      ]),
      const SizedBox(height: 20),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3,
              crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.9),
          itemCount: cards.length, itemBuilder: (_, i) => cards[i]),
      const SizedBox(height: 16),
      Row(children: [
        const Spacer(),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async { await showOrderDialog(context); setState(() {}); },
            icon: const Icon(Icons.add, size: 16), label: const Text('Add New Order')),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        const Spacer(),
        SizedBox(width: 260, child: TextField(onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search'))),
      ]),
      const SizedBox(height: 14),
      OTable(list: os, sel: sel,
          tog: (o) => setState(() => sel.contains(o.id) ? sel.remove(o.id) : sel.add(o.id)),
          del: (o) => setState(() => Store.delOrder(o.id))),
    ]));
  }

  static Widget _lg(Color c, String t) => Padding(padding: const EdgeInsets.only(left: 12),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(fontSize: 11, color: T.grey)),
      ]));
}

class DriversScreen extends StatelessWidget {
  final void Function(String)? onProfile;
  const DriversScreen({super.key, this.onProfile});
  @override
  Widget build(BuildContext context) {
    final ds = Store.drivers();
    final act = ds.where((d) => d.shiftOpen).toList();
    final off = ds.where((d) => !d.shiftOpen).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.lock_clock, size: 16), label: const Text('Close All Shifts'),
            onPressed: () async {
              if (!await confirm(context, 'قفل كل الشيفتات دلوقتي؟')) return;
              final r = Store.closeAll();
              final co = r.fold<double>(0, (a, e) => a + e.company);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم قفل ${r.length} شيفت — حصة الشركة: ${co.toStringAsFixed(0)} EGP')));
            }),
        const Spacer(),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.add, size: 16), label: const Text('Add New Driver'),
            onPressed: () async { await showDriverDialog(context); }),
      ]),
      const SizedBox(height: 16),
      const Center(child: Text('ACTIVE ⚡', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
      const SizedBox(height: 20),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4,
              crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.78),
          itemCount: act.length,
          itemBuilder: (_, i) => DriverCard(d: act[i],
              open: () => onProfile?.call(act[i].id),
              close: () async {
                final d = act[i];
                if (!await confirm(context, 'قفل شيفت ${d.name}؟\nالإجمالي: ${Store.todayTotal(d).toStringAsFixed(0)} EGP\nحصة الشركة ${d.percentage.toStringAsFixed(0)}% والباقي للمندوب')) return;
                final st = Store.closeShift(d);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('شركة ${st.company.toStringAsFixed(0)} — مندوب ${st.driverShare.toStringAsFixed(0)} EGP')));
              })),
      const SizedBox(height: 24),
      const Center(child: Text('OFFLINE / SHIFT CLOSED',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555560)))),
      const SizedBox(height: 20),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4,
              crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.78),
          itemCount: off.length,
          itemBuilder: (_, i) => DriverCard(d: off[i], open: () => onProfile?.call(off[i].id))),
    ]));
  }
}

class DriverProfileScreen extends StatefulWidget {
  final String id;
  final VoidCallback onBack;
  const DriverProfileScreen({super.key, required this.id, required this.onBack});
  @override
  State<DriverProfileScreen> createState() => _DPS();
}

class _DPS extends State<DriverProfileScreen> {
  late Driver d = Store.drivers().firstWhere((x) => x.id == widget.id);
  late final TextEditingController pctC = TextEditingController(text: d.percentage.toStringAsFixed(0));
  void _refresh() => setState(() => d = Store.drivers().firstWhere((x) => x.id == widget.id));

  @override
  Widget build(BuildContext context) {
    final total = Store.todayTotal(d);
    final co = total * d.percentage / 100;
    final hist = Store.settl(d.id);
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [
        const Spacer(),
        ElevatedButton(onPressed: widget.onBack,
            style: ElevatedButton.styleFrom(backgroundColor: T.dark),
            child: const Text('Back', style: TextStyle(color: Colors.white))),
      ]),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 320, child: Column(children: [
          Container(width: 220,
              decoration: BoxDecoration(color: d.shiftOpen ? T.primary : const Color(0xFF0D0D0F),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 12, offset: const Offset(0, 6))]),
              child: Column(children: [
                const SizedBox(height: 14),
                Container(width: 130, height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person, size: 100, color: Color(0xFF33333A))),
                const SizedBox(height: 14),
                Text(d.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (int i = 0; i < 5; i++) const Icon(Icons.star, size: 16, color: T.yellow)]),
                const SizedBox(height: 16),
              ])),
          const SizedBox(height: 20),
          _f('Name', d.name), _f('PHONE NUMBER', d.phone), _f('ID', d.nid), _f('Start', d.start),
          Row(children: [
            Expanded(child: TextField(controller: pctC, decoration: const InputDecoration(labelText: 'Company % (نسبة الشركة)'))),
            IconButton(icon: const Icon(Icons.save, color: T.primary), onPressed: () {
              Store.putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start,
                  rate: d.rate, active: d.active, shiftOpen: d.shiftOpen,
                  percentage: double.tryParse(pctC.text) ?? d.percentage));
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل النسبة ✔')));
            }),
          ]),
          const SizedBox(height: 10),
          d.shiftOpen
              ? SizedBox(width: double.infinity, height: 44, child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: T.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    if (!await confirm(context, 'قفل الشيفت وتسوية الحساب؟')) return;
                    Store.closeShift(d);
                    _refresh();
                  },
                  icon: const Icon(Icons.lock_clock, size: 16), label: const Text('Close Shift & Settle')))
              : Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: T.red.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('الشيفت مقفول — الحساب متسوي ✔',
                      style: TextStyle(color: T.red, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerRight, child: Text('سجل التسويات', style: TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          ...hist.map((s) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: T.border)),
              child: Row(children: [
                Expanded(child: Text('${s.day}\nإجمالي: ${s.total.toStringAsFixed(0)} EGP', style: const TextStyle(fontSize: 11))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('شركة ${s.percentage.toStringAsFixed(0)}%: ${s.company.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, color: T.red)),
                  Text('مندوب: ${s.driverShare.toStringAsFixed(0)} EGP',
                      style: const TextStyle(fontSize: 11, color: T.green)),
                ]),
              ]))),
        ])),
        const SizedBox(width: 24),
        Expanded(child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,
                crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.7),
            itemCount: 4,
            itemBuilder: (_, i) => [
              StatCard(title: 'Orders Today (Delivered)',
                  value: '${Store.orders().where((o) => o.driver == d.name && o.day == Store.today() && o.status == OS.delivered).length}',
                  delta: '40%'),
              StatCard(title: 'Total Today', value: '${total.toStringAsFixed(0)} EGP'),
              StatCard(title: 'Company Share ${d.percentage.toStringAsFixed(0)}%', value: co.toStringAsFixed(0), sc: T.red, up: false),
              StatCard(title: 'Driver Share ${(100 - d.percentage).toStringAsFixed(0)}%', value: (total - co).toStringAsFixed(0)),
            ][i])),
      ]),
    ]));
  }

  Widget _f(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: TextEditingController(text: v), enabled: false),
      ]));
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OS();
}

class _OS extends State<OrdersScreen> {
  String q = '';
  final Set<String> sel = {};
  @override
  Widget build(BuildContext context) {
    final os = Store.orders().where((o) => o.customer.toLowerCase().contains(q.toLowerCase())).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: T.border)),
            child: Row(children: [
              IconButton(onPressed: () => setState(() { for (final id in sel.toList()) Store.delOrder(id); sel.clear(); }),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF77777F))),
              const Icon(Icons.mode_edit_outline, size: 16, color: Color(0xFF77777F)),
            ])),
        const Spacer(),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async { await showOrderDialog(context); setState(() {}); },
            icon: const Icon(Icons.add, size: 16), label: const Text('Add New Order')),
        const SizedBox(width: 12),
        SizedBox(width: 260, child: TextField(onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search'))),
      ]),
      const SizedBox(height: 16),
      OTable(list: os, edit: true, sel: sel,
          tog: (o) => setState(() => sel.contains(o.id) ? sel.remove(o.id) : sel.add(o.id)),
          del: (o) => setState(() => Store.delOrder(o.id)),
          edt: (o) async { await showOrderDialog(context, o); setState(() {}); }),
    ]));
  }
}

class StaticsScreen extends StatefulWidget {
  const StaticsScreen({super.key});
  @override
  State<StaticsScreen> createState() => _STS();
}

class _STS extends State<StaticsScreen> {
  int range = 0;
  static const ranges = ['30 days', '90 days', '6 months', 'Custom'];
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Orders Stastics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const Spacer(),
          for (int i = 0; i < ranges.length; i++)
            Padding(padding: const EdgeInsets.only(left: 10),
                child: GestureDetector(onTap: () => setState(() => range = i),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(color: range == i ? const Color(0xFFB03BC7) : const Color(0xFFE3E3E8),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(ranges[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: range == i ? Colors.white : const Color(0xFFB9B9C0)))))),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 320, child: Row(children: [
          SizedBox(width: 430, child: _card('Total Orders', const Stack(children: [
            Positioned(top: 0, right: 0, child: Text('43.18M', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8E2DE2)))),
            Positioned.fill(child: Padding(padding: EdgeInsets.only(top: 24), child: TotalOrdersAreaChart())),
          ]))),
          const SizedBox(width: 20),
          Expanded(child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: 4,
              itemBuilder: (_, i) => [
                Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFFA855F7), Color(0xFF38BDF8), Color(0xFFC026D3)])),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white24,
                            borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white54)),
                            child: const Icon(Icons.monitor_heart, size: 20, color: Colors.white)),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_up, size: 16, color: Color(0xFFB9F6CA)),
                        const Text('12.43%', style: TextStyle(fontSize: 10, color: Colors.white)),
                      ]),
                      const Spacer(),
                      const Text('45.58 %', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const Text('Orders numbers', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ])),
                _mini('10.67%', 'Cancel', true),
                _mini('10.67%', 'New Customers', false),
                _mini('100,000', 'Gross Profit', true),
              ][i])),
        ])),
        const SizedBox(height: 24),
        SizedBox(height: 220, child: Row(children: [
          Expanded(child: _card('TOP Client', Row(children: [
            Expanded(child: Column(children: [
              _thead(['Source', 'Traffic source %']),
              _trow('1', 'Darb El-omda', '55', const Color(0xFF45B8D1)),
              _trow('2', 'Hot Creep', '35', const Color(0xFFD966D9)),
              _trow('3', 'SHAMEY', '10', const Color(0xFF7B2FF7)),
            ])),
            ArcRing(size: 110, th: 12, colors: const [Color(0xFF45B8D1), Color(0xFFD966D9), Color(0xFF7B2FF7)],
                fracs: const [0.55, 0.35, 0.10],
                center: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Text('55 %', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF45B8D1))),
                  Text('Darb El', style: TextStyle(fontSize: 8, color: T.grey)),
                ])),
          ]))),
          const SizedBox(width: 24),
          Expanded(child: _card('TOP Locations', Row(children: [
            Expanded(child: Column(children: [
              _thead(['Locations', 'Num']),
              _trow('1', 'El-SALAM', '155,234', null),
              _trow('2', 'El-shikh zoyed', '89,317', null),
              _trow('3', 'FOX', '17,663', null),
            ])),
            ArcRing(size: 110, th: 12,
                colors: const [Color(0xFF111111), Color(0xFFE11D1D), Color(0xFF2F80ED), Color(0xFFEDEDF2)],
                fracs: const [0.4, 0.25, 0.25, 0.1],
                center: const Text('262,214', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2F80ED)))),
          ]))),
        ])),
      ]));

  Widget _card(String title, Widget child) => Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: T.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Expanded(child: child),
      ]));

  static Widget _mini(String v, String t, bool up) => Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEFEFF2), borderRadius: BorderRadius.circular(14), border: Border.all(color: T.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(t == 'New Customers' ? Icons.person : Icons.monitor_heart, size: 18, color: T.primary)),
          const Spacer(),
          Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 16, color: up ? T.green : T.red),
          const Text('12.43%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),
        Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(t, style: const TextStyle(fontSize: 12)),
      ]));

  Widget _thead(List<String> t) => Container(margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFE9E9EE), borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Expanded(child: Text(t[0], style: const TextStyle(fontSize: 10, color: T.grey))),
        Expanded(child: Text(t[1], style: const TextStyle(fontSize: 10, color: T.grey))),
      ]));

  Widget _trow(String n, String name, String v, Color? dot) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        if (dot != null) ...[
          Container(width: 14, height: 10, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(5))),
          const SizedBox(width: 6),
        ],
        Text(n, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 11))),
        Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ]));
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SS();
}

class _SS extends State<SettingsScreen> {
  late final Map<String, dynamic> s = Store.settings();
  late final adminName = TextEditingController(), adminPass = TextEditingController();
  late final driverName = TextEditingController(text: s['driverName'] as String? ?? '');
  late final driverPct = TextEditingController(text: s['driverPercentage'] as String? ?? '');
  late final pct = TextEditingController(text: s['companyPercentage'] as String? ?? '15');
  late final lang = TextEditingController(text: s['language'] as String? ?? '');

  void save() {
    Store.saveSettings({...s, 'driverName': driverName.text, 'driverPercentage': driverPct.text,
      'companyPercentage': pct.text, 'language': lang.text});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved offline ✔')));
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 460, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _box('Admin', [_f('Name*', adminName, 'Enter your name'), _f('Password*', adminPass, 'Create a password', obscure: true)]),
          const SizedBox(height: 20),
          _box('The percentage (نسبة الشركة للجميع)', [
            _f('%', pct, '15'),
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  Store.applyAll(double.tryParse(pct.text) ?? 15);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تطبيق النسبة على كل المندوبين ✔')));
                },
                icon: const Icon(Icons.group, size: 16), label: const Text('Apply To All Drivers')),
          ]),
          const SizedBox(height: 20),
          _box('Language', [_f('', lang, '')]),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 44, child: ElevatedButton(onPressed: save,
              style: ElevatedButton.styleFrom(backgroundColor: T.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Change', style: TextStyle(color: Colors.white)))),
        ])),
        const SizedBox(width: 60),
        SizedBox(width: 460, child: _box('Percentage For Driver', [_f('Name*', driverName, 'Magdy'), _f('Percentage', driverPct, '20%')])),
      ]));

  Widget _box(String title, List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEFEFF4), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 24),
      ]));

  Widget _f(String label, TextEditingController c, String hint, {bool obscure = false}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        TextField(controller: c, obscureText: obscure, decoration: InputDecoration(hintText: hint)),
      ]));
}

/* ================= الأب ================= */
class ZajilApp extends StatefulWidget {
  const ZajilApp({super.key});
  @override
  State<ZajilApp> createState() => _ZA();
}

class _ZA extends State<ZajilApp> {
  bool logged = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Zajil Admin', debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, primaryColor: T.primary, scaffoldBackgroundColor: T.bg,
          colorScheme: const ColorScheme.light(primary: T.primary),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: T.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: T.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: T.primary, width: 1.5)))),
      home: logged
          ? MainShell(onLogout: () => setState(() => logged = false))
          : LoginScreen(onLogin: () => setState(() => logged = true)));
}
