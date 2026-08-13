import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // تأكد من إضافة هذه المكتبة في pubspec.yaml

// Data model for driver custody
class DriverCustody {
  final String driverId;
  final String driverName;
  final int activeOrders;
  final double totalOrdersValue;
  final double collectedAmount;
  final double handedOverAmount;
  final DateTime lastSettlementDate;
  final List<Settlement> settlements;

  DriverCustody({
    required this.driverId,
    required this.driverName,
    required this.activeOrders,
    required this.totalOrdersValue,
    required this.collectedAmount,
    required this.handedOverAmount,
    required this.lastSettlementDate,
    required this.settlements,
  });

  double get currentCustody => collectedAmount - handedOverAmount;

  CustodyStatus get status {
    if (currentCustody <= 0) return CustodyStatus.Settled;
    // simple overdue logic: if last settlement > 30 days ago and custody > 0 => overdue
    final daysSince = DateTime.now().difference(lastSettlementDate).inDays;
    if (daysSince > 30 && currentCustody > 0) return CustodyStatus.Overdue;
    return CustodyStatus.Pending;
  }
}

class Settlement {
  final DateTime date;
  final double amount;
  final String note;

  Settlement({required this.date, required this.amount, this.note = ''});
}

enum CustodyStatus { Settled, Pending, Overdue }

// Mock service to provide driver custody data. Replace with API later.
class DriverCustodyService {
  // simulate network delay
  Future<List<DriverCustody>> fetchDriverCustodies() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    return [
      DriverCustody(
        driverId: 'd1',
        driverName: 'أحمد محمد',
        activeOrders: 4,
        totalOrdersValue: 420.0,
        collectedAmount: 520.0,
        handedOverAmount: 200.0,
        lastSettlementDate: now.subtract(const Duration(days: 5)),
        settlements: [
          Settlement(date: now.subtract(const Duration(days: 5)), amount: 200.0, note: 'تحويل بنكي'),
        ],
      ),
      DriverCustody(
        driverId: 'd2',
        driverName: 'سليم علي',
        activeOrders: 2,
        totalOrdersValue: 150.0,
        collectedAmount: 150.0,
        handedOverAmount: 150.0,
        lastSettlementDate: now.subtract(const Duration(days: 10)),
        settlements: [
          Settlement(date: now.subtract(const Duration(days: 10)), amount: 150.0, note: 'نقدي'),
        ],
      ),
      DriverCustody(
        driverId: 'd3',
        driverName: 'مريم خالد',
        activeOrders: 6,
        totalOrdersValue: 800.0,
        collectedAmount: 950.0,
        handedOverAmount: 400.0,
        lastSettlementDate: now.subtract(const Duration(days: 45)),
        settlements: [
          Settlement(date: now.subtract(const Duration(days: 45)), amount: 400.0, note: 'تحويل بنكي'),
          Settlement(date: now.subtract(const Duration(days: 90)), amount: 300.0, note: 'نقدي'),
        ],
      ),
      DriverCustody(
        driverId: 'd4',
        driverName: 'خالد يوسف',
        activeOrders: 0,
        totalOrdersValue: 0.0,
        collectedAmount: 0.0,
        handedOverAmount: 0.0,
        lastSettlementDate: now.subtract(const Duration(days: 3)),
        settlements: [],
      ),
    ];
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DriverCustodyService _service = DriverCustodyService();
  late Future<List<DriverCustody>> _futureData;

  // UI state
  List<DriverCustody> _drivers = [];
  String _search = '';
  CustodyStatus? _filterStatus;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _sortByHighestCustody = false;
  bool _sortByOverdue = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureData = _service.fetchDriverCustodies();
    _futureData.then((value) {
      setState(() {
        _drivers = value;
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Calculations
  double get outstandingCustody => _drivers.fold(0.0, (p, d) => p + d.currentCustody);

  int get driversWithIssuesCount => _drivers.where((d) => d.status == CustodyStatus.Pending || d.status == CustodyStatus.Overdue).length;

  List<DriverCustody> get filteredDrivers {
    var list = List<DriverCustody>.from(_drivers);
    if (_search.isNotEmpty) {
      list = list.where((d) => d.driverName.contains(_search)).toList();
    }
    if (_filterStatus != null) {
      list = list.where((d) => d.status == _filterStatus).toList();
    }
    if (_fromDate != null) {
      list = list.where((d) => d.lastSettlementDate.isAfter(_fromDate!.subtract(const Duration(days: 1)))).toList();
    }
    if (_toDate != null) {
      list = list.where((d) => d.lastSettlementDate.isBefore(_toDate!.add(const Duration(days: 1)))).toList();
    }
    if (_sortByHighestCustody) {
      list.sort((a, b) => b.currentCustody.compareTo(a.currentCustody));
    }
    if (_sortByOverdue) {
      list.sort((a, b) => (b.status == CustodyStatus.Overdue ? 1 : 0).compareTo(a.status == CustodyStatus.Overdue ? 1 : 0));
    }
    return list;
  }

  void _resetFilters() {
    setState(() {
      _search = '';
      _searchController.text = '';
      _filterStatus = null;
      _fromDate = null;
      _toDate = null;
      _sortByHighestCustody = false;
      _sortByOverdue = false;
    });
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  void _reviewCustody() {
    setState(() {
      _filterStatus = CustodyStatus.Pending;
      _sortByOverdue = true;
    });
  }

  void _showDetails(DriverCustody d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تفاصيل الحجز المالي — ${d.driverName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إجمالي الطلبات: ${d.activeOrders}'),
              const SizedBox(height: 8),
              Text('قيمة الطلبات الإجمالية: ${d.totalOrdersValue.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('إجمالي المقبوضات: ${d.collectedAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('المسلم للشركة: ${d.handedOverAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('الرصيد الحالي: ${d.currentCustody.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('آخر تسوية: ${d.lastSettlementDate.toLocal().toString().split(' ').first}'),
              const SizedBox(height: 12),
              const Text('سجل التسويات السابقة', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (d.settlements.isEmpty) const Text('لا توجد تسويات سابقة'),
              for (var s in d.settlements)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.amount.toStringAsFixed(2)),
                  subtitle: Text('${s.date.toLocal().toString().split(' ').first} — ${s.note}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _statusBadge(CustodyStatus status) {
    switch (status) {
      case CustodyStatus.Settled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF12B76A).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: const Text('تم التسوية', style: TextStyle(color: Color(0xFF12B76A), fontWeight: FontWeight.bold)),
        );
      case CustodyStatus.Pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFFFA726).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: const Text('قيد الانتظار', style: TextStyle(color: Color(0xFFFFA726), fontWeight: FontWeight.bold)),
        );
      case CustodyStatus.Overdue:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFFF5252).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: const Text('متأخر', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
        );
    }
  }

  // UI builders for the section
  Widget _buildCustodySummaryCards() {
    final totalActive = _drivers.fold<double>(0.0, (p, d) => p + (d.currentCustody > 0 ? d.currentCustody : 0.0));
    final totalCollected = _drivers.fold<double>(0.0, (p, d) => p + d.collectedAmount);
    final totalHanded = _drivers.fold<double>(0.0, (p, d) => p + d.handedOverAmount);
    final outstanding = outstandingCustody;

    final styleTitle = TextStyle(color: Colors.grey[600], fontSize: 13);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 3,
      children: [
        _custodyCard('إجمالي الحجز النشط', totalActive, styleTitle, const Color(0xFF6C5DD3)),
        _custodyCard('إجمالي المقبوضات', totalCollected, styleTitle, const Color(0xFFFF7629)),
        _custodyCard('إجمالي المسلم', totalHanded, styleTitle, const Color(0xFF00C9A7)),
        _custodyCard('الرصيد المستحق', outstanding, styleTitle, const Color(0xFFFF5252)),
      ],
    );
  }

  Widget _custodyCard(String title, double value, TextStyle titleStyle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 8),
              Text('"); // placeholder', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.account_balance_wallet_rounded, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: 'بحث عن سائق...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onChanged: (v) => setState(() {
              _search = v;
            }),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<CustodyStatus?>(
          value: _filterStatus,
          hint: const Text('حالة'),
          items: [
            const DropdownMenuItem(value: null, child: Text('الكل')),
            DropdownMenuItem(value: CustodyStatus.Settled, child: const Text('تم التسوية')),
            DropdownMenuItem(value: CustodyStatus.Pending, child: const Text('قيد الانتظار')),
            DropdownMenuItem(value: CustodyStatus.Overdue, child: const Text('متأخر')),
          ],
          onChanged: (v) => setState(() => _filterStatus = v),
        ),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: _selectFromDate, child: Text(_fromDate == null ? 'من' : _fromDate!.toLocal().toString().split(' ').first)),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _selectToDate, child: Text(_toDate == null ? 'إلى' : _toDate!.toLocal().toString().split(' ').first)),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => setState(() => _sortByHighestCustody = !_sortByHighestCustody),
          icon: Icon(Icons.sort, color: _sortByHighestCustody ? Colors.blue : Colors.grey),
          tooltip: 'فرز حسب أعلى رصيد',
        ),
        IconButton(
          onPressed: () => setState(() => _sortByOverdue = !_sortByOverdue),
          icon: Icon(Icons.warning, color: _sortByOverdue ? Colors.red : Colors.grey),
          tooltip: 'فرز حسب المتأخرين',
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _resetFilters, child: const Text('إعادة')),
      ],
    );
  }

  Widget _buildDriverCustodyTable() {
    final list = filteredDrivers;
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('لا توجد بيانات لعرضها')),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: const [
          DataColumn(label: Text('السائق')),
          DataColumn(label: Text('الطلبات النشطة')),
          DataColumn(label: Text('قيمة الطلبات')),
          DataColumn(label: Text('المقبوض')),
          DataColumn(label: Text('المسلم')),
          DataColumn(label: Text('الرصيد الحالي')),
          DataColumn(label: Text('آخر تسوية')),
          DataColumn(label: Text('الحالة')),
          DataColumn(label: Text('الإجراءات')),
        ],
        rows: list.map((d) {
          return DataRow(cells: [
            DataCell(Text(d.driverName)),
            DataCell(Text(d.activeOrders.toString())),
            DataCell(Text(d.totalOrdersValue.toStringAsFixed(2))),
            DataCell(Text(d.collectedAmount.toStringAsFixed(2))),
            DataCell(Text(d.handedOverAmount.toStringAsFixed(2))),
            DataCell(Text(d.currentCustody.toStringAsFixed(2))),
            DataCell(Text(d.lastSettlementDate.toLocal().toString().split(' ').first)),
            DataCell(_statusBadge(d.status)),
            DataCell(Row(children: [IconButton(icon: const Icon(Icons.remove_red_eye), onPressed: () => _showDetails(d))])),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FE),
        body: FutureBuilder<List<DriverCustody>>(
          future: _futureData,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('حدث خطأ أثناء جلب البيانات'));
            }
            // data loaded
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Warning alert
                  if (driversWithIssuesCount > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$driversWithIssuesCount سائق لديهم أرصدة مستحقة أو متأخرة', style: const TextStyle(color: Colors.black87)),
                          ElevatedButton(onPressed: _reviewCustody, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7629)), child: const Text('مراجعة الحجز')),
                        ],
                      ),
                    ),

                  // Section title
                  const Text('Driver Financial Custody', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Summary cards
                  _buildCustodySummaryCards(),
                  const SizedBox(height: 16),

                  // Filters
                  _buildFilters(),
                  const SizedBox(height: 16),

                  // Table title
                  const Text('Driver Custody Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Table
                  _buildDriverCustodyTable(),

                  const SizedBox(height: 24),

                  // keep the recent orders table below as before
                  const SizedBox(height: 30),
                  // You can reuse the existing recent orders table if needed; kept out for safety.
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
