import 'package:flutter/material.dart';
import 'core.dart';
import 'package:fl_chart/fl_chart.dart'; // تأكد من إضافة هذه المكتبة في pubspec.yaml

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _userInfo = '';

  void _updateUserInfo(String value) {
    setState(() {
      if (value.isNotEmpty) {
        _userInfo = 'مرحباً بك، $value!';
      } else {
        _userInfo = '';
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width * 0.75,
        color: const Color(0xFFE0B0FF), // Mauve color
        child: Row(
          children: [
            // Left side - Logo
            Expanded(
              flex: 1,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      width: MediaQuery.of(context).size.width * 0.75 * 0.5,
                      child: const ZajilLogo(),
                    ),
                  ],
                ),
              ),
            ),
            // Right side - Login Form with white background
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Label that shows when typing username
                    if (_userInfo.isNotEmpty) ...[
                      Text(
                        _userInfo,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Username Label
                    Text(
                      'اسم المستخدم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        onChanged: _updateUserInfo,
                        decoration: InputDecoration(
                          hintText: 'أدخل اسم المستخدم',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFFFFF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Password Label
                    Text(
                      'كلمة المرور',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'أدخل كلمة المرور',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFFFFF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DashboardScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5DD3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // جعل الاتجاه من اليمين لليسار
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FE),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. الرأس (Header)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحباً بك، صالح! 👋',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إليك ملخص أداء متجرك اليوم',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الأحد، 24 أكتوبر 2023',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildIconButton(Icons.notifications_outlined),
                      const SizedBox(width: 12),
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://i.pravatar.cc/150?img=11',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 2. بطاقات الإحصائيات (Stats Cards)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard(
                    'إجمالي الإيرادات',
                    '\$45,231',
                    '+20.1%',
                    Icons.attach_money,
                    const Color(0xFF6C5DD3),
                    isUp: true,
                  ),
                  _buildStatCard(
                    'إجمالي الطلبات',
                    '3,456',
                    '+15.2%',
                    Icons.shopping_bag_outlined,
                    const Color(0xFFFF7629),
                    isUp: true,
                  ),
                  _buildStatCard(
                    'إجمالي السائقين',
                    '456',
                    '-3.5%',
                    Icons.directions_car_outlined,
                    const Color(0xFF12B76A),
                    isUp: false,
                  ),
                  _buildStatCard(
                    'أرباح الشركة',
                    '\$12,345',
                    '+8.4%',
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFF00C9A7),
                    isUp: true,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 3. قسم التحليلات والحالة (Analytics & Status)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المخطط البياني
                  Expanded(
                    flex: 2,
                    child: _buildChartCard(),
                  ),
                  const SizedBox(width: 20),
                  // حالة الطلبات
                  Expanded(
                    flex: 1,
                    child: _buildStatusCard(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 4. جدول الطلبات الحديثة
              _buildRecentOrdersTable(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Builders ---

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Icon(icon, color: Colors.grey[700]),
    );
  }

  Widget _buildStatCard(String title, String value, String change, IconData icon, Color color, {required bool isUp}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isUp ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  color: isUp ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text('vs الشهر الماضي', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإيرادات والطلبات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 40, color: const Color(0xFF6C5DD3), width: 12)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 70, color: const Color(0xFF6C5DD3), width: 12)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 50, color: const Color(0xFF6C5DD3), width: 12)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 90, color: const Color(0xFF6C5DD3), width: 12)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 60, color: const Color(0xFF6C5DD3), width: 12)]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 80, color: const Color(0xFF6C5DD3), width: 12)]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 100, color: const Color(0xFF6C5DD3), width: 12)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حالة الطلبات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStatusItem('قيد التنفيذ', '24', const Color(0xFFFF7629)),
          const SizedBox(height: 15),
          _buildStatusItem('تم التوصيل', '456', const Color(0xFF12B76A)),
          const SizedBox(height: 15),
          _buildStatusItem('معلق', '12', Colors.grey),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5DD3),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('عرض كل الطلبات'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String title, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildRecentOrdersTable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الطلبات الحديثة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة طلب جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5DD3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[500], size: 18),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'بحث...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              columns: const [
                DataColumn(label: Text('رقم الطلب')),
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('السائق')),
                DataColumn(label: Text('المبلغ')),// تم التصحيح
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('الإجراءات')),
              ],
              rows: List.generate(5, (index) {
                return DataRow(cells: [
                  DataCell(Text('#SKTG${2340 + index}')),
                  DataCell(Text('24 أكتوبر 2023')),
                  DataCell(Row(children: [
                    CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 5}')),
                    const SizedBox(width: 8),
                    const Text('أحمد محمد'),
                  ])),
                  DataCell(Text('\$${(120 + index * 10).toString()}')),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? const Color(0xFF12B76A).withOpacity(0.1) : const Color(0xFFFF7629).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      index % 2 == 0 ? 'مكتمل' : 'قيد التنفيذ',
                      style: TextStyle(
                        color: index % 2 == 0 ? const Color(0xFF12B76A) : const Color(0xFFFF7629),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                  DataCell(IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {})),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }
}
