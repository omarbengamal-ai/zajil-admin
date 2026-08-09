import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/* ===== الثيم (دارك مود) ===== */
class T {
  static bool dark = false;
  static const primary = Color(0xFF6750C4), darkP = Color(0xFF4B32A8), light = Color(0xFF9B86E4),
      lighter = Color(0xFFC4B8F0), green = Color(0xFF2E9E5B), red = Color(0xFFD64545),
      orange = Color(0xFFB9770E), yellow = Color(0xFFE7C11A);
  static const r = 10.0;
  static Color get bg => dark ? const Color(0xFF141419) : const Color(0xFFF5F5F9);
  static Color get card => dark ? const Color(0xFF1F1F26) : Colors.white;
  static Color get field => dark ? const Color(0xFF2A2A33) : Colors.white;
  static Color get border => dark ? const Color(0xFF2C2C35) : const Color(0xFFE4E4EC);
  static Color get text => dark ? const Color(0xFFF2F2F5) : const Color(0xFF202028);
  static Color get grey => dark ? const Color(0xFF9A9AA5) : const Color(0xFF8A8A94);
  static Color get box => dark ? const Color(0xFF232329) : const Color(0xFFEFEFF4);
  static Color get rowAlt => dark ? const Color(0xFF232329) : const Color(0xFFF7F7FB);
}

/* ===== النماذج ===== */
enum OS { delivered, inProgress, canceled, onTheRoad }
OS osFrom(String s) => OS.values.firstWhere((e) => e.name == s, orElse: () => OS.inProgress);
extension OSX on OS {
  String get label => ['Delivered', 'IN Progress', 'Canceled', 'On The Road'][index];
  Color get fg => [T.green, const Color(0xFF9A9AA5), T.red, T.orange][index];
  Color get bg => [const Color(0xFFE6F6EC), const Color(0xFF3A3A42), const Color(0xFFFBE9E9), const Color(0xFFFDF3E1)][index];
}

class Order {
  final String id, customer, from, to, driver, date, day, audio;
  final double total; final OS status;
  const Order({required this.id, required this.customer, required this.status, required this.from,
      required this.to, required this.driver, required this.date, this.day = '', this.audio = '', this.total = 0});
  Map<String, dynamic> toMap() => {'id': id, 'customer': customer, 'status': status.name, 'from': from, 'to': to, 'driver': driver, 'date': date, 'day': day, 'audio': audio, 'total': total};
  factory Order.fromMap(Map m) => Order(id: m['id'] ?? '', customer: m['customer'] ?? '', status: osFrom(m['status'] ?? ''), from: m['from'] ?? '', to: m['to'] ?? '', driver: m['driver'] ?? '', date: m['date'] ?? '', day: m['day'] ?? '', audio: m['audio'] ?? '', total: (m['total'] as num? ?? 0).toDouble());
}

class Driver {
  final String id, name, phone, nid, start, photo;
  final int rate; final bool active, shiftOpen; final double percentage;
  const Driver({required this.id, required this.name, required this.phone, required this.nid,
      required this.start, required this.rate, this.active = true, this.shiftOpen = true, this.percentage = 15, this.photo = ''});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'phone': phone, 'nid': nid, 'start': start, 'rate': rate, 'active': active, 'shiftOpen': shiftOpen, 'percentage': percentage, 'photo': photo};
  factory Driver.fromMap(Map m) => Driver(id: m['id'] ?? '', name: m['name'] ?? '', phone: m['phone'] ?? '', nid: m['nid'] ?? '', start: m['start'] ?? '', rate: m['rate'] as int? ?? 5, active: m['active'] as bool? ?? true, shiftOpen: m['shiftOpen'] as bool? ?? true, percentage: (m['percentage'] as num? ?? 15).toDouble(), photo: m['photo'] ?? '');
}

class Settl {
  final String id, driverId, driverName, day, closedAt;
  final double total, company, driverShare, percentage;
  const Settl({required this.id, required this.driverId, required this.driverName, required this.day,
      required this.closedAt, required this.total, required this.company, required this.driverShare, required this.percentage});
  Map<String, dynamic> toMap() => {'id': id, 'driverId': driverId, 'driverName': driverName, 'day': day, 'closedAt': closedAt, 'total': total, 'company': company, 'driverShare': driverShare, 'percentage': percentage};
  factory Settl.fromMap(Map m) => Settl(id: m['id'] ?? '', driverId: m['driverId'] ?? '', driverName: m['driverName'] ?? '', day: m['day'] ?? '', closedAt: m['closedAt'] ?? '', total: (m['total'] as num? ?? 0).toDouble(), company: (m['company'] as num? ?? 0).toDouble(), driverShare: (m['driverShare'] as num? ?? 0).toDouble(), percentage: (m['percentage'] as num? ?? 0).toDouble());
}

/* ===== المخزن ===== */
class Store {
  static late Box _o, _d, _s, _st;
  static String today() => DateTime.now().toIso8601String().substring(0, 10);
  static Future<void> init() async {
    await Hive.initFlutter();
    _o = await Hive.openBox('o'); _d = await Hive.openBox('d'); _s = await Hive.openBox('s'); _st = await Hive.openBox('st');
    if (!_s.containsKey('data')) _s.put('data', {'adminName': 'Saleh', 'companyPercentage': '15', 'language': 'English', 'dark': '0'});
  }
  static void dailyReset() {
    final t = today();
    for (final d in drivers()) if (!d.shiftOpen && !settl(d.id).any((x) => x.day == t))
      putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: true, shiftOpen: true, percentage: d.percentage, photo: d.photo));
  }
  static List<Order> orders() => _o.values.map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  static List<Driver> drivers() => _d.values.map((e) => Driver.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  static List<Settl> settl([String? id]) => _st.values.map((e) => Settl.fromMap(Map<String, dynamic>.from(e as Map))).where((x) => id == null || x.driverId == id).toList()..sort((a, b) => b.id.compareTo(a.id));
  static Map<String, dynamic> settings() => Map<String, dynamic>.from(_s.get('data') as Map? ?? {});
  static void saveSettings(Map<String, dynamic> m) => _s.put('data', m);
  static void clearAll() { _o.clear(); _d.clear(); _st.clear(); }
  static void putOrder(Order o) => _o.put(o.id, o.toMap());
  static void delOrder(String id) => _o.delete(id);
  static void putDriver(Driver d) => _d.put(d.id, d.toMap());
  static void applyAll(double p) {
    for (final d in drivers()) putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: d.active, shiftOpen: d.shiftOpen, percentage: p, photo: d.photo));
    saveSettings(settings()..['companyPercentage'] = p.toStringAsFixed(0));
  }
  static double todayTotal(Driver d) => orders().where((o) => o.driver == d.name && o.day == today() && o.status == OS.delivered).fold(0.0, (a, o) => a + o.total);
  static Settl closeShift(Driver d) {
    final total = todayTotal(d), co = total * d.percentage / 100;
    final st = Settl(id: 's${DateTime.now().millisecondsSinceEpoch}', driverId: d.id, driverName: d.name, day: today(), closedAt: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}', total: total, company: co, driverShare: total - co, percentage: d.percentage);
    _st.put(st.id, st.toMap());
    putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: false, shiftOpen: false, percentage: d.percentage, photo: d.photo));
    return st;
  }
  static List<Settl> closeAll() => [for (final d in drivers()) if (d.shiftOpen) closeShift(d)];
}

/* ===== الصوت ===== */
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
    await rec.start(const RecordConfig(encoder: AudioEncoder.wav), path: p);
    return p;
  }
  static Future<String?> stop() => rec.stop();
  static Future<void> toggle(String p) async {
    _e();
    if (playing.value == p) { await pl.stop(); playing.value = null; }
    else { await pl.stop(); await pl.play(DeviceFileSource(p)); playing.value = p; }
  }
}

/* ===== التفريغ الأوفلاين ===== */
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
    if (_complete(bundled)) return bundled.path;
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
            whisper: sherpa.OfflineWhisperModelConfig(encoder: '$dir/encoder.onnx', decoder: '$dir/decoder.onnx', language: 'ar', task: 'transcribe'))));
  }
  static Future<String> run(File wav) async {
    await init((_) {});
    final bytes = await wav.readAsBytes();
    final b = ByteData.sublistView(bytes);
    int off = 12, ch = 1, rate = 16000, dOff = -1, dLen = 0;
    while (off + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes.sublist(off, off + 4));
      final sz = b.getUint32(off + 4, Endian.little);
      final body = off + 8;
      if (id == 'fmt ') { ch = b.getUint16(body + 2, Endian.little); rate = b.getUint32(body + 4, Endian.little); }
      else if (id == 'data') { dOff = body; dLen = sz; }
      off = body + sz + (sz.isOdd ? 1 : 0);
    }
    if (dOff < 0) throw 'ملف صوت غير مدعوم';
    final n = (dLen ~/ 2) ~/ ch;
    final s = Float32List(n);
    for (int i = 0; i < n; i++) { int x = 0; for (int c = 0; c < ch; c++) x += b.getInt16(dOff + (i * ch + c) * 2, Endian.little); s[i] = x / ch / 32768; }
    final st = _rec!.createStream();
    st.acceptWaveform(samples: s, sampleRate: rate);
    _rec!.decode(st);
    return _rec!.getResult(st).text.trim();
  }
}

/* ===== أنيميشن + فاضي + لوجو ===== */
class Enter extends StatefulWidget {
  final Widget child; final int ms;
  const Enter({super.key, required this.child, this.ms = 0});
  @override
  State<Enter> createState() => _En();
}
class _En extends State<Enter> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  @override
  void initState() { super.initState(); Future.delayed(Duration(milliseconds: widget.ms), () { if (mounted) c.forward(); }); }
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: c,
      child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)), child: widget.child));
}

class Empty extends StatelessWidget {
  final String m;
  const Empty(this.m, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(40),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 44, color: T.grey),
        const SizedBox(height: 8),
        Text(m, style: TextStyle(color: T.grey, fontSize: 13)),
      ])));
}

class ZajilLogo extends StatelessWidget {
  final double size;
  const ZajilLogo({super.key, this.size = 70});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * .22),
          gradient: const LinearGradient(colors: [Color(0xFF7A1FA2), Color(0xFF5B1283)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: const Color(0xFF3E0B5C), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFF7A1FA2).withOpacity(.4), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🕊️', style: TextStyle(fontSize: size * .24)),
        Text('زاجل', style: TextStyle(fontSize: size * .3, fontWeight: FontWeight.w900, color: T.yellow)),
        Text('ZAJIL', style: TextStyle(fontSize: size * .12, letterSpacing: 2, color: T.yellow)),
      ]));
}

/* ===== رسم ===== */
class Rings extends StatelessWidget {
  final double size; final String label;
  const Rings(this.label, {super.key, this.size = 200});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
      child: CustomPaint(painter: _RP(), child: Center(child: Text(label, style: TextStyle(fontSize: size * .15, fontWeight: FontWeight.w700, color: T.text)))));
}
class _RP extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ce = s.center(Offset.zero); final b = s.shortestSide / 2;
    for (final f in [1.0, .8, .6]) c.drawArc(Rect.fromCircle(center: ce, radius: b * f - b * .08), 0, 2 * math.pi, false, Paint()..color = (T.dark ? const Color(0xFF2C2C35) : const Color(0xFFE9E9F0))..style = PaintingStyle.stroke..strokeWidth = b * .16);
    const sp = [[T.darkP, 1.0, .88], [T.light, .8, .72], [T.lighter, .6, .55]];
    for (final x in sp) c.drawArc(Rect.fromCircle(center: ce, radius: b * (x[1] as double) - b * .08), -math.pi / 2, 2 * math.pi * (x[2] as double), false, Paint()..color = x[0] as Color..style = PaintingStyle.stroke..strokeWidth = b * .16..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Spark extends StatelessWidget {
  final bool up; final Color? color;
  const Spark({super.key, this.up = true, this.color});
  @override
  Widget build(BuildContext context) {
    final pts = up ? const [.85, .6, .72, .45, .55, .3, .42, .12] : const [.15, .35, .28, .5, .45, .62, .56, .8];
    return CustomPaint(size: const Size(64, 34), painter: _SP(pts, color ?? (up ? T.green : T.red)));
  }
}
class _SP extends CustomPainter {
  final List<double> p; final Color c;
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
  final double size, th; final List<Color> colors; final List<double> fracs; final Widget? center;
  const ArcRing({super.key, required this.size, required this.th, required this.colors, required this.fracs, this.center});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _ArcP(colors, fracs, th), child: Center(child: center)));
}
class _ArcP extends CustomPainter {
  final List<Color> colors; final List<double> fracs; final double th;
  _ArcP(this.colors, this.fracs, this.th);
  @override
  void paint(Canvas c, Size s) {
    final ce = s.center(Offset.zero); final r = s.shortestSide / 2 - th / 2;
    double start = -math.pi / 2;
    for (int i = 0; i < colors.length; i++) { c.drawArc(Rect.fromCircle(center: ce, radius: r), start, 2 * math.pi * fracs[i] - 0.04, false, Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = th); start += 2 * math.pi * fracs[i]; }
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
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: T.border, strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 18, getTitlesWidget: (v, _) {
          final i = v.toInt(); if (i < 0 || i > 11) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[i], style: TextStyle(fontSize: 10, color: T.grey)));
        }))),
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
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 58, interval: 50000, getTitlesWidget: (v, _) => Text(v.toStringAsFixed(2), style: TextStyle(fontSize: 9, color: T.grey)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 18, getTitlesWidget: (v, _) {
          const l = {0: 'Oct', 4: 'Nov', 8: 'Dec', 12: 'Janv'}; final t = l[v.toInt()];
          if (t == null) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(t, style: TextStyle(fontSize: 10, color: t == 'Dec' ? const Color(0xFFB03BC7) : T.grey)));
        }))),
      extraLinesData: ExtraLinesData(verticalLines: [VerticalLine(x: 8, color: T.primary.withOpacity(.35), strokeWidth: 1)]),
      lineBarsData: [LineChartBarData(
          spots: [for (var i = 0; i < vals.length; i++) FlSpot(i.toDouble(), vals[i])],
          isCurved: true, preventCurveOverShooting: true, color: const Color(0xFFA43BC4), barWidth: 2,
          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => i == 8 ? FlDotCirclePainter(radius: 4, color: T.darkP) : FlDotCirclePainter(radius: 0, color: Colors.transparent)),
          belowBarData: BarAreaData(show: true, gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99A43BC4), Color(0x0AA43BC4)])))]));
}

/* ===== كروت ===== */
class StatCard extends StatelessWidget {
  final String title, value; final String? delta; final bool up; final String vs; final Color? sc; final bool spark;
  const StatCard({super.key, required this.title, required this.value, this.delta, this.up = true, this.vs = 'vs last month', this.sc, this.spark = true});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(T.r), border: Border.all(color: T.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(T.dark ? .3 : .04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: T.text))), Icon(Icons.more_vert, size: 16, color: T.grey)]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: T.text)),
        const Spacer(),
        Row(children: [
          if (delta != null) ...[Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: sc ?? (up ? T.green : T.red)),
            Text(' ${delta!} ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc ?? (up ? T.green : T.red)))],
          Expanded(child: Text(vs, style: TextStyle(fontSize: 11, color: T.grey))),
          if (spark) Spark(up: up, color: sc),
        ]),
      ]));
}

class PlainCard extends StatelessWidget {
  final String? title; final Widget child;
  const PlainCard({super.key, this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(T.r), border: Border.all(color: T.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null) Row(children: [Expanded(child: Text(title!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.text))), Icon(Icons.more_vert, size: 16, color: T.grey)]),
        if (title != null) const SizedBox(height: 10),
        Expanded(child: child),
      ]));
}

class DriverCard extends StatefulWidget {
  final Driver d; final VoidCallback? open, close;
  const DriverCard({super.key, required this.d, this.open, this.close});
  @override
  State<DriverCard> createState() => _DC();
}
class _DC extends State<DriverCard> {
  bool hov = false;
  @override
  Widget build(BuildContext context) {
    final d = widget.d; final on = d.active && d.shiftOpen;
    final hasPhoto = d.photo.isNotEmpty && File(d.photo).existsSync();
    return MouseRegion(onEnter: (_) => setState(() => hov = true), onExit: (_) => setState(() => hov = false),
      child: AnimatedScale(scale: hov ? 1.03 : 1, duration: const Duration(milliseconds: 180),
        child: GestureDetector(onTap: widget.open,
          child: Container(constraints: const BoxConstraints(minWidth: 160),
            decoration: BoxDecoration(color: on ? T.primary : const Color(0xFF0D0D0F), borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: (on ? T.primary : Colors.black).withOpacity(.35), blurRadius: hov ? 18 : 10, offset: const Offset(0, 6))]),
            child: Column(children: [
              const SizedBox(height: 12),
              Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: hasPhoto ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(d.photo), fit: BoxFit.cover)) : const Icon(Icons.person, size: 74, color: Color(0xFF33333A))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(d.name.toUpperCase(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                const SizedBox(width: 4), Icon(Icons.bolt, size: 14, color: on ? const Color(0xFF38EF7D) : const Color(0xFF9A9AA2)),
              ]),
              const SizedBox(height: 8),
              const Text('RATE', style: TextStyle(fontSize: 10, color: Colors.white70)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [for (int i = 0; i < 5; i++) Icon(Icons.star, size: 16, color: i < d.rate ? T.yellow : Colors.white24)]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('الش
