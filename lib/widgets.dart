import 'dart:io';
import 'package:flutter/material.dart';
import 'core.dart';

/* ===== كارت المندوب (هوفر + صورة) ===== */
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
                Text('الشركة ${d.percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                if (on && widget.close != null) IconButton(onPressed: widget.close, tooltip: 'قفل الشيفت وتسوية الحساب', icon: const Icon(Icons.lock_clock, size: 18, color: T.yellow)),
                if (!on) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: T.red.withOpacity(.85), borderRadius: BorderRadius.circular(4)), child: const Text('SHIFT CLOSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white))),
              ]),
              const SizedBox(height: 10),
            ])))));
  }
}

/* ===== جدول الأوردرات ===== */
class OTable extends StatelessWidget {
  final List<Order> list; final bool edit; final Set<String> sel; final Function(Order)? tog, del, edt;
  const OTable({super.key, required this.list, this.edit = false, this.sel = const {}, this.tog, this.del, this.edt});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(T.r), border: Border.all(color: T.border)),
      child: list.isEmpty ? const Empty('مفيش أوردرات لسه — ضيف أول أوردر من زرار Add New Order') : Column(children: [_h(), for (int i = 0; i < list.length; i++) _r(i)]));
  Widget _h() => Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: T.border))),
      child: Row(children: [
        const SizedBox(width: 40, child: Icon(Icons.remove_circle_outline, size: 15, color: T.primary)),
        Expanded(flex: 3, child: Text('Customer ↓', style: TextStyle(fontSize: 11, color: T.grey))),
        for (final t in ['Status', 'From', 'To', 'Driver', 'Date', 'Total']) Expanded(flex: 2, child: Text(t, style: TextStyle(fontSize: 11, color: T.grey))),
        const SizedBox(width: 110),
      ]));
  Widget _r(int i) {
    final o = list[i]; final s = sel.contains(o.id);
    return Container(color: i.isEven ? T.card : T.rowAlt, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(children: [
          SizedBox(width: 40, child: GestureDetector(onTap: () => tog?.call(o),
              child: Container(width: 18, height: 18, decoration: BoxDecoration(color: T.field, borderRadius: BorderRadius.circular(4), border: Border.all(color: s ? T.primary : const Color(0xFFC9C9D4), width: 1.4)), child: s ? const Icon(Icons.check, size: 13, color: T.primary) : null))),
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(radius: 15, backgroundColor: T.primary, child: Text(o.customer.isNotEmpty ? o.customer[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12, color: Colors.white))),
            const SizedBox(width: 8),
            Flexible(child: Text(o.customer, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: T.text))),
          ])),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: o.status.bg, borderRadius: BorderRadius.circular(4)), child: Text(o.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: o.status.fg)))),
          Expanded(flex: 2, child: Text(o.from, style: TextStyle(fontSize: 12, color: T.text))),
          Expanded(flex: 2, child: Text(o.to, style: TextStyle(fontSize: 12, color: T.text))),
          Expanded(flex: 2, child: Text(o.driver, style: TextStyle(fontSize: 12, color: T.text))),
          Expanded(flex: 2, child: Text(o.date, style: TextStyle(fontSize: 12, color: T.text))),
          Expanded(flex: 2, child: Text('${o.total.toStringAsFixed(0)} EGP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: T.text))),
          SizedBox(width: 110, child: Row(children: [
            if (o.audio.isNotEmpty) ValueListenableBuilder<String?>(valueListenable: Audio_.playing, builder: (_, p, __) => IconButton(onPressed: () => Audio_.toggle(o.audio), icon: Icon(p == o.audio ? Icons.stop_circle_outlined : Icons.volume_up, size: 18, color: p == o.audio ? T.red : T.primary))),
            IconButton(onPressed: () => del?.call(o), icon: Icon(Icons.delete_outline, size: 17, color: T.grey)),
            if (edit) IconButton(onPressed: () => edt?.call(o), icon: Icon(Icons.mode_edit_outline, size: 16, color: T.grey)),
          ])),
        ]));
  }
}

/* ===== السايدبار ===== */
class Sidebar extends StatelessWidget {
  final int sel; final ValueChanged<int> on; final Widget? extra; final VoidCallback onLogout;
  const Sidebar({super.key, required this.sel, required this.on, required this.onLogout, this.extra});
  static const it = [
    ['Dashboard', Icons.bar_chart, 0], ['Drivers', Icons.layers, 1], ['Orders', Icons.fact_check_outlined, 2],
    ['Statics', Icons.flag_outlined, 3], ['Settings', Icons.settings, 4],
  ];
  @override
  Widget build(BuildContext context) => Container(width: 220, padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [ZajilLogo(size: 64)]),
        const SizedBox(height: 16),
        for (final x in it)
          Container(margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: sel == x[2] as int ? T.primary : T.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel == x[2] as int ? T.primary : T.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(T.dark ? .3 : .05), blurRadius: 4, offset: const Offset(0, 2))]),
              child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => on(x[2] as int),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(children: [
                        Icon(x[1] as IconData, size: 18, color: sel == x[2] as int ? Colors.white : T.grey),
                        const SizedBox(width: 10),
                        Text(x[0] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel == x[2] as int ? Colors.white : T.text)),
                      ])))),
        const Spacer(),
        if (extra != null) extra!,
        Divider(color: T.border),
        Row(children: [
          const CircleAvatar(radius: 15, backgroundColor: Color(0xFFE4D9F7), child: Icon(Icons.person, size: 18, color: T.primary)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Saleh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: T.text)),
            Text('Saleh@admin.com', style: TextStyle(fontSize: 10, color: T.grey)),
          ])),
          IconButton(onPressed: onLogout, icon: Icon(Icons.logout, size: 18, color: T.grey)),
        ]),
      ]));
}

Future<bool> confirm(BuildContext c, String m) async =>
    (await showDialog<bool>(context: c, builder: (c2) => AlertDialog(
        title: const Text('تأكيد'), content: Text(m),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c2, false), child: const Text('لا')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: T.primary), onPressed: () => Navigator.pop(c2, true), child: const Text('أيوة')),
        ]))) ?? false;

/* ===== حوار الأوردر (مايك محمي) ===== */
Future<void> showOrderDialog(BuildContext context, [Order? existing]) => showDialog(context: context, builder: (_) => _OrderDialog(existing: existing));

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

  Future<void> toggleMic() async {
    try {
      if (!rec) {
        final p = await Audio_.start();
        if (p == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسمح للبرنامج يستخدم المايك من إعدادات ويندوز → Privacy → Microphone'))); return; }
        audioId = p;
        setState(() { rec = true; sec = 0; });
        Future.doWhile(() async {
          if (!rec || !mounted) return false;
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) setState(() => sec++);
          return rec;
        });
      } else {
        setState(() { rec = false; busy = true; });
        final p = await Audio_.stop();
        if (p != null) audioId = p;
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
      }
    } catch (e) {
      if (mounted) { setState(() { rec = false; busy = false; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مشكلة في المايك/التفريغ: $e'))); }
    } finally { if (mounted) setState(() => busy = false); }
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
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: T.dark ? const Color(0xFF2A2A33) : const Color(0xFFF4F1FC), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              busy ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: T.primary)))
                  : IconButton(onPressed: toggleMic, tooltip: 'اتكلّم وهو يملّي الأوردر', icon: Icon(rec ? Icons.stop_circle : Icons.mic, color: rec ? T.red : T.primary)),
              Expanded(child: Text(rec ? 'جارٍ التسجيل.. ${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')} ⏺' : busy ? 'بنفرّغ الكلام ✍️' : 'دوس المايك وقول: عميل حسن من مطعم الشرق الى مدينة نصر', style: const TextStyle(fontSize: 11))),
              if (audioId != null) IconButton(icon: const Icon(Icons.play_arrow, size: 20, color: T.primary), onPressed: () => Audio_.toggle(audioId!)),
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
          Expanded(child: TextField(controller: totalC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Total (EGP)'))),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<OS>(value: status, items: [for (final s in OS.values) DropdownMenuItem(value: s, child: Text(s.label))], onChanged: (v) => setState(() => status = v!)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: T.primary), onPressed: save, child: const Text('Save')),
      ]);
}

/* ===== حوار إضافة مندوب ===== */
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
        DropdownButtonFormField<int>(value: rate, items: [for (int i = 1; i <= 5; i++) DropdownMenuItem(value: i, child: Text('$i ★'))], onChanged: (v) => setSt(() => rate = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: T.primary), onPressed: () {
          final id = 'd${DateTime.now().millisecondsSinceEpoch}';
          Store.putDriver(Driver(id: id, name: name.text.isEmpty ? 'NEW DRIVER' : name.text, phone: phone.text, nid: nid.text, start: Store.today(), rate: rate, active: true, shiftOpen: true, percentage: double.tryParse(pct.text) ?? 15));
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ])));
}
