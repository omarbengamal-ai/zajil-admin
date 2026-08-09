import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'core.dart';
import 'widgets.dart';

/* ===== تسجيل الدخول ===== */
/* ===== تسجيل الدخول (لوجو زاجل + خلفية موف) ===== */
class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LS();
}
class _LS extends State<LoginScreen> {
  final _n = TextEditingController(), _p = TextEditingController();
  void go() {
    if (_n.text.isEmpty || _p.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your name and password'))); return; }
    Store.saveSettings(Store.settings()..['adminName'] = _n.text);
    widget.onLogin();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF5B1283), // نفس درجة الموف بتاعة اللوجو
      body: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Enter(child: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Log in', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('زاجل — سرعة .. تسليم .. دقة', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 24),
          const Text('Name*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          TextField(controller: _n, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Enter your name')),
          const SizedBox(height: 16),
          const Text('Password*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          TextField(controller: _p, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Create a password')),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 46, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: T.yellow, foregroundColor: const Color(0xFF3E0B5C),
                  elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: go, child: const Text('Log in', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
        ]))),
        const SizedBox(width: 70),
        Enter(ms: 150, child: Image.asset('logo.png', width: 360, height: 360, fit: BoxFit.contain)),
      ])));
}
/* ===== الهيكل الرئيسي (هيدر + سايدبار + انتقالات) ===== */
class MainShell extends StatefulWidget {
  final VoidCallback onLogout; final VoidCallback onToggleDark;
  const MainShell({super.key, required this.onLogout, required this.onToggleDark});
  @override
  State<MainShell> createState() => _MS();
}
class _MS extends State<MainShell> {
  int page = 0; String? profileId;
  static const titles = ['Dashboard', 'Drivers', 'Orders', 'Statics', 'Settings'];
  @override
  Widget build(BuildContext context) => Scaffold(body: Column(children: [
    Container(height: 64, color: T.primary, child: Stack(children: [
      Center(child: Text(page == 5 ? 'Profile' : titles[page], style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800))),
      Align(alignment: Alignment.centerRight, child: IconButton(tooltip: 'دارك مود', onPressed: widget.onToggleDark,
          icon: Icon(T.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.white))),
    ])),
    Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Sidebar(sel: page > 4 ? 1 : page, on: (i) => setState(() => page = i), onLogout: widget.onLogout, extra: (page == 1 || page == 2) ? _ring() : null),
      Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 280),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: const Offset(.03, 0), end: Offset.zero).animate(a), child: c)),
          child: Container(key: ValueKey(page), child: _content()))),
    ])),
  ]));
  Widget _ring() => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(page == 1 ? 'Active now' : 'Orders Delivering Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: T.text))), Icon(Icons.more_vert, size: 14, color: T.grey)]),
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
      default: return DriverProfileScreen(id: profileId ?? '', onBack: () => setState(() => page = 1));
    }
  }
}

/* ===== الداشبورد ===== */
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DS();
}
class _DS extends State<DashboardScreen> {
  String q = ''; final Set<String> sel = {};
  @override
  Widget build(BuildContext context) {
    final os = Store.orders().where((o) => o.customer.toLowerCase().contains(q.toLowerCase())).toList();
    final t = Store.today(); final all = Store.orders();
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
        Enter(child: SizedBox(width: 330, height: 280, child: PlainCard(title: 'Active now', child: Center(child: Rings('$inProg', size: 210))))),
        const SizedBox(width: 20),
        Enter(ms: 100, child: SizedBox(height: 280, child: Expanded(child: PlainCard(title: 'Total customers', child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [_lg(const Color(0xFF9B86E4), '2021'), _lg(const Color(0xFFC4B8F0), '2020'), _lg(const Color(0xFF3F2B96), '2019')]),
          const Expanded(child: CustomersLineChart()),
        ]))))),
      ]),
      const SizedBox(height: 20),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.9),
          itemCount: cards.length, itemBuilder: (_, i) => Enter(ms: i * 60, child: cards[i])),
      const SizedBox(height: 16),
      Row(children: [const Spacer(), ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: T.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () async { await showOrderDialog(context); setState(() {}); },
          icon: const Icon(Icons.add, size: 16), label: const Text('Add New Order'))]),
      const SizedBox(height: 14),
      Row(children: [const Spacer(), SizedBox(width: 260, child: TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search')))]),
      const SizedBox(height: 14),
      Enter(ms: 120, child: OTable(list: os, sel: sel,
          tog: (o) => setState(() => sel.contains(o.id) ? sel.remove(o.id) : sel.add(o.id)),
          del: (o) => setState(() => Store.delOrder(o.id)))),
    ]));
  }
  static Widget _lg(Color c, String t) => Padding(padding: const EdgeInsets.only(left: 12), child: Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4), Text(t, style: TextStyle(fontSize: 11, color: T.grey)),
  ]));
}

/* ===== المندوبين ===== */
class DriversScreen extends StatelessWidget {
  final void Function(String)? onProfile;
  const DriversScreen({super.key, this.onProfile});
  @override
  Widget build(BuildContext context) {
    final act = Store.drivers().where((d) => d.shiftOpen).toList();
    final off = Store.drivers().where((d) => !d.shiftOpen).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.lock_clock, size: 16), label: const Text('Close All Shifts'),
            onPressed: () async {
              if (!await confirm(context, 'قفل كل الشيفتات دلوقتي؟')) return;
              final r = Store.closeAll(); final co = r.fold<double>(0, (a, e) => a + e.company);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم قفل ${r.length} شيفت — حصة الشركة: ${co.toStringAsFixed(0)} EGP')));
            }),
        const Spacer(),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.add, size: 16), label: const Text('Add New Driver'),
            onPressed: () async { await showDriverDialog(context); }),
      ]),
      const SizedBox(height: 16),
      Center(child: Text('ACTIVE ⚡', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: T.text))),
      const SizedBox(height: 20),
      act.isEmpty ? const Empty('مفيش مندوبين لسه — ضيف أول مندوب من Add New Driver') :
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.78),
          itemCount: act.length,
          itemBuilder: (_, i) => Enter(ms: i * 70, child: DriverCard(d: act[i],
              open: () => onProfile?.call(act[i].id),
              close: () async {
                final d = act[i];
                if (!await confirm(context, 'قفل شيفت ${d.name}؟\nالإجمالي: ${Store.todayTotal(d).toStringAsFixed(0)} EGP\nحصة الشركة ${d.percentage.toStringAsFixed(0)}% والباقي للمندوب')) return;
                final st = Store.closeShift(d);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('شركة ${st.company.toStringAsFixed(0)} — مندوب ${st.driverShare.toStringAsFixed(0)} EGP')));
              }))),
      const SizedBox(height: 24),
      Center(child: Text('OFFLINE / SHIFT CLOSED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: T.grey))),
      const SizedBox(height: 20),
      off.isEmpty ? const SizedBox.shrink() :
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 0.78),
          itemCount: off.length,
          itemBuilder: (_, i) => Enter(ms: i * 70, child: DriverCard(d: off[i], open: () => onProfile?.call(off[i].id)))),
    ]));
  }
}

/* ===== بروفايل المندوب (رفع صورة + نسبة + تسويات) ===== */
class DriverProfileScreen extends StatefulWidget {
  final String id; final VoidCallback onBack;
  const DriverProfileScreen({super.key, required this.id, required this.onBack});
  @override
  State<DriverProfileScreen> createState() => _DPS();
}
class _DPS extends State<DriverProfileScreen> {
  late Driver d = Store.drivers().firstWhere((x) => x.id == widget.id,
      orElse: () => const Driver(id: 'x', name: '—', phone: '—', nid: '—', start: '—', rate: 5));
  late final TextEditingController pctC = TextEditingController(text: d.percentage.toStringAsFixed(0));
  void _refresh() => setState(() => d = Store.drivers().firstWhere((x) => x.id == widget.id,
      orElse: () => const Driver(id: 'x', name: '—', phone: '—', nid: '—', start: '—', rate: 5)));

  Future<void> _pickPhoto() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      final bytes = r?.files.first.bytes;
      if (bytes == null) return;
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/zajil_photos')..createSync(recursive: true);
      final f = File('${dir.path}/${d.id}.png');
      await f.writeAsBytes(bytes);
      Store.putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: d.active, shiftOpen: d.shiftOpen, percentage: d.percentage, photo: f.path));
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مشكلة في رفع الصورة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = Store.todayTotal(d);
    final co = total * d.percentage / 100;
    final hist = Store.settl(d.id);
    final hasPhoto = d.photo.isNotEmpty && File(d.photo).existsSync();
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [const Spacer(), ElevatedButton(onPressed: widget.onBack,
          style: ElevatedButton.styleFrom(backgroundColor: T.darkP), child: const Text('Back', style: TextStyle(color: Colors.white)))]),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 320, child: Column(children: [
          Container(width: 220,
              decoration: BoxDecoration(color: d.shiftOpen ? T.primary : const Color(0xFF0D0D0F), borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 12, offset: const Offset(0, 6))]),
              child: Column(children: [
                const SizedBox(height: 14),
                Container(width: 130, height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: hasPhoto ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(d.photo), fit: BoxFit.cover)) : const Icon(Icons.person, size: 100, color: Color(0xFF33333A))),
                const SizedBox(height: 10),
                ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                    onPressed: _pickPhoto, icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    label: const Text('رفع صورة', style: TextStyle(fontSize: 11, color: Colors.white))),
                const SizedBox(height: 10),
                Text(d.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (int i = 0; i < 5; i++) const Icon(Icons.star, size: 16, color: T.yellow)]),
                const SizedBox(height: 16),
              ])),
          const SizedBox(height: 20),
          _f('Name', d.name), _f('PHONE NUMBER', d.phone), _f('ID', d.nid), _f('Start', d.start),
          Row(children: [
            Expanded(child: TextField(controller: pctC, decoration: const InputDecoration(labelText: 'Company % (نسبة الشركة)'))),
            IconButton(icon: const Icon(Icons.save, color: T.primary), onPressed: () {
              Store.putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: d.active, shiftOpen: d.shiftOpen, percentage: double.tryParse(pctC.text) ?? d.percentage, photo: d.photo));
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل النسبة ✔')));
            }),
          ]),
          const SizedBox(height: 10),
          d.shiftOpen
              ? SizedBox(width: double.infinity, height: 44, child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: T.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    if (!await confirm(context, 'قفل الشيفت وتسوية الحساب؟')) return;
                    Store.closeShift(d); _refresh();
                  },
                  icon: const Icon(Icons.lock_clock, size: 16), label: const Text('Close Shift & Settle')))
              : Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: T.red.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('الشيفت مقفول — الحساب متسوي ✔', style: TextStyle(color: T.red, fontWeight: FontWeight.w700))),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: Text('سجل التسويات', style: TextStyle(fontWeight: FontWeight.w800, color: T.text))),
          const SizedBox(height: 8),
          ...hist.map((s) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: T.border)),
              child: Row(children: [
                Expanded(child: Text('${s.day}\nإجمالي: ${s.total.toStringAsFixed(0)} EGP', style: TextStyle(fontSize: 11, color: T.text))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('شركة ${s.percentage.toStringAsFixed(0)}%: ${s.company.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: T.red)),
                  Text('مندوب: ${s.driverShare.toStringAsFixed(0)} EGP', style: const TextStyle(fontSize: 11, color: T.green)),
                ]),
              ]))),
        ])),
        const SizedBox(width: 24),
        Expanded(child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.7),
            itemCount: 4,
            itemBuilder: (_, i) => Enter(ms: i * 60, child: [
              StatCard(title: 'Orders Today (Delivered)', value: '${Store.orders().where((o) => o.driver == d.name && o.day == Store.today() && o.status == OS.delivered).length}', delta: '40%'),
              StatCard(title: 'Total Today', value: '${total.toStringAsFixed(0)} EGP'),
              StatCard(title: 'Company Share ${d.percentage.toStringAsFixed(0)}%', value: co.toStringAsFixed(0), sc: T.red, up: false),
              StatCard(title: 'Driver Share ${(100 - d.percentage).toStringAsFixed(0)}%', value: (total - co).toStringAsFixed(0)),
            ][i]))),
      ]),
    ]));
  }
  Widget _f(String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(fontSize: 12)), const SizedBox(height: 6),
    TextField(controller: TextEditingController(text: v), enabled: false),
  ]));
}

/* ===== الأوردرات ===== */
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OS();
}
class _OS extends State<OrdersScreen> {
  String q = ''; final Set<String> sel = {};
  @override
  Widget build(BuildContext context) {
    final os = Store.orders().where((o) => o.customer.toLowerCase().contains(q.toLowerCase())).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: T.border)),
            child: Row(children: [
              IconButton(onPressed: () => setState(() { for (final id in sel.toList()) Store.delOrder(id); sel.clear(); }),
                  icon: Icon(Icons.delete_outline, size: 18, color: T.grey)),
              Icon(Icons.mode_edit_outline, size: 16, color: T.grey),
            ])),
        const Spacer(),
        ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async { await showOrderDialog(context); setState(() {}); },
            icon: const Icon(Icons.add, size: 16), label: const Text('Add New Order')),
        const SizedBox(width: 12),
        SizedBox(width: 260, child: TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search'))),
      ]),
      const SizedBox(height: 16),
      OTable(list: os, edit: true, sel: sel,
          tog: (o) => setState(() => sel.contains(o.id) ? sel.remove(o.id) : sel.add(o.id)),
          del: (o) => setState(() => Store.delOrder(o.id)),
          edt: (o) async { await showOrderDialog(context, o); setState(() {}); }),
    ]));
  }
}

/* ===== الإحصائيات ===== */
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
          Text('Orders Stastics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: T.text)),
          const Spacer(),
          for (int i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(onTap: () => setState(() => range = i),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(color: range == i ? const Color(0xFFB03BC7) : T.box, borderRadius: BorderRadius.circular(10)),
                      child: Text(ranges[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: range == i ? Colors.white : T.grey))))),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 300, child: Row(children: [
          SizedBox(width: 430, child: const PlainCard(title: 'Total Orders', child: TotalOrdersAreaChart())),
          const SizedBox(width: 20),
          Expanded(child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: 4,
              itemBuilder: (_, i) => Enter(ms: i * 60, child: const [
                StatCard(title: 'Orders numbers', value: '45.58 %', delta: '12.43%'),
                StatCard(title: 'Cancel', value: '10.67%', delta: '12.43%'),
                StatCard(title: 'New Customers', value: '10.67%', delta: '1.2%', up: false),
                StatCard(title: 'Gross Profit', value: '100,000', delta: '12.43%'),
              ][i]))),
        ])),
        const SizedBox(height: 24),
        SizedBox(height: 220, child: Row(children: [
          Expanded(child: PlainCard(title: 'TOP Client', child: Row(children: [
            Expanded(child: Column(children: [
              _trow('1', 'Darb El-omda', '55', const Color(0xFF45B8D1)),
              _trow('2', 'Hot Creep', '35', const Color(0xFFD966D9)),
              _trow('3', 'SHAMEY', '10', const Color(0xFF7B2FF7))])),
            ArcRing(size: 110, th: 12, colors: const [Color(0xFF45B8D1), Color(0xFFD966D9), Color(0xFF7B2FF7)], fracs: const [.55, .35, .10],
                center: const Text('55 %', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF45B8D1)))),
          ]))),
          const SizedBox(width: 24),
          Expanded(child: PlainCard(title: 'TOP Locations', child: Row(children: [
            Expanded(child: Column(children: [
              _trow('1', 'El-SALAM', '155,234', null),
              _trow('2', 'El-shikh zoyed', '89,317', null),
              _trow('3', 'FOX', '17,663', null)])),
            ArcRing(size: 110, th: 12, colors: const [Color(0xFF111111), Color(0xFFE11D1D), Color(0xFF2F80ED), Color(0xFFEDEDF2)], fracs: const [.4, .25, .25, .1],
                center: const Text('262,214', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2F80ED)))),
          ]))),
        ])),
      ]));
  Widget _trow(String n, String name, String v, Color? dot) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
    if (dot != null) ...[Container(width: 14, height: 10, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(5))), const SizedBox(width: 6)],
    Text(n, style: TextStyle(fontSize: 11, color: T.grey)), const SizedBox(width: 8),
    Expanded(child: Text(name, style: TextStyle(fontSize: 11, color: T.text))),
    Text(v, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: T.text)),
  ]));
}

/* ===== الإعدادات ===== */
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
    Store.saveSettings({...s, 'driverName': driverName.text, 'driverPercentage': driverPct.text, 'companyPercentage': pct.text, 'language': lang.text});
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
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: T.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () { Store.applyAll(double.tryParse(pct.text) ?? 15);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تطبيق النسبة على كل المندوبين ✔'))); },
                icon: const Icon(Icons.group, size: 16), label: const Text('Apply To All Drivers')),
          ]),
          const SizedBox(height: 20),
          _box('Language', [_f('', lang, '')]),
          const SizedBox(height: 26),
          Row(children: [
            Expanded(child: SizedBox(height: 44, child: ElevatedButton(onPressed: save,
                style: ElevatedButton.styleFrom(backgroundColor: T.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Change', style: TextStyle(color: Colors.white))))),
            const SizedBox(width: 12),
            Expanded(child: SizedBox(height: 44, child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: T.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  if (!await confirm(context, 'مسح كل البيانات نهائيًا من الجهاز؟')) return;
                  Store.clearAll(); setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح كل البيانات ✔')));
                },
                icon: const Icon(Icons.delete_forever, size: 16), label: const Text('مسح كل البيانات')))),
          ]),
        ])),
        const SizedBox(width: 60),
        SizedBox(width: 460, child: _box('Percentage For Driver', [_f('Name*', driverName, 'Magdy'), _f('Percentage', driverPct, '20%')])),
      ]));
  Widget _box(String title, List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: T.box, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: T.text)),
        const SizedBox(height: 10), ...children, const SizedBox(height: 24),
      ]));
  Widget _f(String label, TextEditingController c, String hint, {bool obscure = false}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        TextField(controller: c, obscureText: obscure, decoration: InputDecoration(hintText: hint)),
      ]));
}

/* ===== الأب ===== */
class ZajilApp extends StatefulWidget {
  const ZajilApp({super.key});
  @override
  State<ZajilApp> createState() => _ZA();
}
class _ZA extends State<ZajilApp> {
  bool logged = false;
  void _toggleDark() { T.dark = !T.dark; Store.saveSettings(Store.settings()..['dark'] = T.dark ? '1' : '0'); setState(() {}); }
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Zajil Admin', debugShowCheckedModeBanner: false, theme: _theme(),
      home: logged ? MainShell(onLogout: () => setState(() => logged = false), onToggleDark: _toggleDark)
                   : LoginScreen(onLogin: () => setState(() => logged = true)));
  ThemeData _theme() => ThemeData(useMaterial3: false, primaryColor: T.primary,
      scaffoldBackgroundColor: T.bg, cardColor: T.card, dividerColor: T.border, dialogBackgroundColor: T.card,
      colorScheme: (T.dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(primary: T.primary),
      textTheme: TextTheme(bodyMedium: TextStyle(color: T.text), titleMedium: TextStyle(color: T.text)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: T.field,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: T.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: T.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: T.primary, width: 1.5))));
}
