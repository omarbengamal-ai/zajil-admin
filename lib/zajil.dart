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

/* ===== الثيم (ألوان زاجل + radius مطابق للمشروع المرفوع 0.625rem) ===== */
class T {
  static const primary = Color(0xFF6750C4), dark = Color(0xFF4B32A8), light = Color(0xFF9B86E4),
      lighter = Color(0xFFC4B8F0), bg = Color(0xFFF5F5F9), border = Color(0xFFE4E4EC),
      grey = Color(0xFF8A8A94), green = Color(0xFF2E9E5B), red = Color(0xFFD64545),
      orange = Color(0xFFB9770E), yellow = Color(0xFFE7C11A);
  static const r = 10.0;
}

/* ===== النماذج ===== */
enum OS { delivered, inProgress, canceled, onTheRoad }
OS osFrom(String s) => OS.values.firstWhere((e) => e.name == s, orElse: () => OS.inProgress);
extension OSX on OS {
  String get label => ['Delivered', 'IN Progress', 'Canceled', 'On The Road'][index];
  Color get fg => [T.green, const Color(0xFF555560), T.red, T.orange][index];
  Color get bg => [const Color(0xFFE6F6EC), const Color(0xFFEDEDF2), const Color(0xFFFBE9E9), const Color(0xFFFDF3E1)][index];
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
  final String id, name, phone, nid, start; final int rate; final bool active, shiftOpen; final double percentage;
  const Driver({required this.id, required this.name, required this.phone, required this.nid, required this.start, required this.rate, this.active = true, this.shiftOpen = true, this.percentage = 15});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'phone': phone, 'nid': nid, 'start': start, 'rate': rate, 'active': active, 'shiftOpen': shiftOpen, 'percentage': percentage};
  factory Driver.fromMap(Map m) => Driver(id: m['id'] ?? '', name: m['name'] ?? '', phone: m['phone'] ?? '', nid: m['nid'] ?? '', start: m['start'] ?? '', rate: m['rate'] as int? ?? 5, active: m['active'] as bool? ?? true, shiftOpen: m['shiftOpen'] as bool? ?? true, percentage: (m['percentage'] as num? ?? 15).toDouble());
}

class Settl {
  final String id, driverId, driverName, day, closedAt; final double total, company, driverShare, percentage;
  const Settl({required this.id, required this.driverId, required this.driverName, required this.day, required this.closedAt, required this.total, required this.company, required this.driverShare, required this.percentage});
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
    _seed();
  }
  static void _seed() {
    final t = today();
    if (_o.isEmpty) {
      const L = [Order(id: 'o1', customer: 'Hot creep', status: OS.delivered, from: 'Restaurant', to: 'Fox Square', driver: 'MAGDY MAHMOUD', date: '12:15 AM', total: 250), Order(id: 'o2', customer: 'Darb El3omdaa', status: OS.delivered, from: 'Restaurant', to: 'Elsalam', driver: 'MAGDY MAHMOUD', date: '12:15 AM', total: 350), Order(id: 'o3', customer: 'Bazz', status: OS.canceled, from: 'Restaurant', to: 'Garden city', driver: 'darsh', date: '12:15 AM', total: 180), Order(id: 'o4', customer: '7assan', status: OS.onTheRoad, from: 'elshikh zaied', to: 'ELmostakbal', driver: 'ahmed', date: '12:15 AM', total: 220), Order(id: 'o5', customer: 'Layers', status: OS.onTheRoad, from: 'Restaurant', to: '3oraby', driver: 'omar', date: '12:15 AM', total: 140), Order(id: 'o6', customer: 'Quotient', status: OS.delivered, from: 'Restaurant', to: 'Elhorrya st', driver: 'MAGDY MAHMOUD', date: '12:15 AM', total: 400), Order(id: 'o7', customer: 'Sisyphus', status: OS.delivered, from: 'Restaurant', to: 'ELtalatiny', driver: 'saleh', date: '12:15 AM', total: 300)];
      for (var o in L) _o.put(o.id, o.toMap()..['day'] = t);
    }
    if (_d.isEmpty) {
      for (int i = 1; i <= 4; i++) _d.put('a$i', Driver(id: 'a$i', name: 'MAGDY MAHMOUD', phone: '0128525648', nid: '20185649852695262', start: '11/2/2025', rate: 5).toMap());
      for (int i = 1; i <= 4; i++) _d.put('f$i', Driver(id: 'f$i', name: 'MAGDY MAHMOUD', phone: '0128525648', nid: '20185649852695262', start: '11/2/2025', rate: 5, active: false, shiftOpen: false).toMap());
    }
    if (!_s.containsKey('data')) _s.put('data', {'adminName': 'Saleh', 'companyPercentage': '15', 'language': 'English'});
  }
  static void dailyReset() { final t = today(); for (final d in drivers()) if (!d.shiftOpen && !settl(d.id).any((x) => x.day == t)) putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: true, shiftOpen: true, percentage: d.percentage)); }
  static List<Order> orders() => _o.values.map((e) => Order.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  static List<Driver> drivers() => _d.values.map((e) => Driver.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  static List<Settl> settl([String? id]) => _st.values.map((e) => Settl.fromMap(Map<String, dynamic>.from(e as Map))).where((x) => id == null || x.driverId == id).toList()..sort((a, b) => b.id.compareTo(a.id));
  static Map<String, dynamic> settings() => Map<String, dynamic>.from(_s.get('data') as Map? ?? {});
  static void saveSettings(Map<String, dynamic> m) => _s.put('data', m);
  static void putOrder(Order o) => _o.put(o.id, o.toMap());
  static void delOrder(String id) => _o.delete(id);
  static void putDriver(Driver d) => _d.put(d.id, d.toMap());
  static void applyAll(double p) { for (final d in drivers()) putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: d.active, shiftOpen: d.shiftOpen, percentage: p)); saveSettings(settings()..['companyPercentage'] = p.toStringAsFixed(0)); }
  static double todayTotal(Driver d) => orders().where((o) => o.driver == d.name && o.day == today() && o.status == OS.delivered).fold(0.0, (a, o) => a + o.total);
    static Settl closeShift(Driver d) {
    final total = todayTotal(d), co = total * d.percentage / 100;
    final st = Settl(id: 's${DateTime.now().millisecondsSinceEpoch}', driverId: d.id, driverName: d.name, day: today(), closedAt: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}', total: total, company: co, driverShare: total - co, percentage: d.percentage);
    _st.put(st.id, st.toMap());
    putDriver(Driver(id: d.id, name: d.name, phone: d.phone, nid: d.nid, start: d.start, rate: d.rate, active: false, shiftOpen: false, percentage: d.percentage));
    return st;
  }
  static List<Settl> closeAll() => [for (final d in drivers()) if (d.shiftOpen) closeShift(d)];
}
