import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:sherpa_onnx/sherpa_onnx.dart';

// Existing login screen kept above dashboard in this file
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Container(
          // width 75% of screen, height 100%
          width: screenSize.width * 0.75,
          height: screenSize.height,
          color: const Color(0xFF6C5DD3), // Mauve background
          child: LayoutBuilder(builder: (context, constraints) {
            final containerWidth = constraints.maxWidth;
            final containerHeight = constraints.maxHeight;

            return Stack(
              children: [
                // Logo placed above the background
                Positioned(
                  top: containerHeight * 0.05,
                  left: (containerWidth - (containerWidth * 0.5)) / 2,
                  child: SizedBox(
                    width: containerWidth * 0.5, // 50% width
                    height: containerHeight * 0.6, // 60% height
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Replace with your asset or network logo
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.network(
                                'https://i.pravatar.cc/300?img=47',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Zajil',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right side: username & password labels/fields
                Positioned(
                  right: containerWidth * 0.06,
                  top: containerHeight * 0.25,
                  child: SizedBox(
                    width: containerWidth * 0.35,
                    // height: containerHeight * 0.4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // label that reflects username input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // The label text: shows entered username; invisible when empty
                              Text(
                                _usernameController.text.isEmpty ? 'اسم المستخدم' : _usernameController.text,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: _usernameController.text.isEmpty ? const Color(0x00000000) : Colors.black, // transparent when empty (#0000), black when typed
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // actual input field (keeps white background)
                              TextField(
                                controller: _usernameController,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  hintText: 'ادخل اسم المستخدم',
                                  border: InputBorder.none,
                                ),
                                onChanged: (v) {
                                  setState(() {}); // update label
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'كلمة المرور',
                                textAlign: TextAlign.right,
                                style: TextStyle(color: Color(0xFF000000), fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  hintText: 'ادخل كلمة المرور',
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // For now, just print values and navigate to dashboard
                              if (_usernameController.text.isNotEmpty) {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('تسجيل الدخول'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Dashboard: redesigned to dark, modern style
// Includes button to add new order (speech-to-text or manual)
// Orders can be assigned to drivers that have profiles
// This file now includes basic sherpa_onnx integration for offline STT.
// You must provide sherpa-onnx model files in app documents/models/ or allow the app to download them.
// --------------------------------------------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Record _recorder = Record();
  bool _isRecording = false;
  String? _recordedFilePath;
  String _transcription = '';

  SherpaOnnxRecognize? _transcriber; // note: class name depends on package API; adjust if necessary

  List<Map<String, dynamic>> drivers = [
    {'id': 'd1', 'name': 'أحمد محمد', 'avatar': 'https://i.pravatar.cc/150?img=5', 'hasProfile': true},
    {'id': 'd2', 'name': 'سامي علي', 'avatar': 'https://i.pravatar.cc/150?img=6', 'hasProfile': true},
    {'id': 'd3', 'name': 'محمود حسن', 'avatar': 'https://i.pravatar.cc/150?img=7', 'hasProfile': false},
  ];

  List<Map<String, dynamic>> orders = [];

  // Expected model filenames inside app documents/models/
  final List<String> _requiredModelFiles = [
    'encoder.onnx',
    'decoder.onnx',
    'joiner.onnx',
    'tokens.txt',
  ];

  // Placeholder URLs for model download guidance.
  // Replace with official sherpa-onnx model URLs or host your own copies.
  final Map<String, String> _modelDownloadUrls = {
    'encoder.onnx': 'https://example.com/models/encoder.onnx',
    'decoder.onnx': 'https://example.com/models/decoder.onnx',
    'joiner.onnx': 'https://example.com/models/joiner.onnx',
    'tokens.txt': 'https://example.com/models/tokens.txt',
  };

  Future<Directory> _modelsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final models = Directory('${dir.path}/models');
    if (!await models.exists()) await models.create(recursive: true);
    return models;
  }

  Future<bool> _modelsExist() async {
    final models = await _modelsDir();
    for (final f in _requiredModelFiles) {
      if (!await File('${models.path}/$f').exists()) return false;
    }
    return true;
  }

  Future<void> _downloadModels(BuildContext context) async {
    final models = await _modelsDir();
    for (final f in _requiredModelFiles) {
      final url = _modelDownloadUrls[f];
      if (url == null) continue;
      final localPath = '${models.path}/$f';
      final file = File(localPath);
      if (await file.exists()) continue;
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        await file.writeAsBytes(resp.bodyBytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تحميل $f من $url')));
      }
    }
  }

  Future<void> _initTranscriberIfReady(BuildContext context) async {
    if (_transcriber != null) return;
    final ok = await _modelsExist();
    if (!ok) {
      // Prompt user to download models or place them manually
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('نماذج صعبة'),
          content: const Text('نماذج Sherpa-ONNX غير موجودة. هل تريد تنزيلها الآن (الحجم قد يكون كبيرًا)؟'),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('لا')),
            TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('نعم')),
          ],
        ),
      );

      if (shouldDownload == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تنزيل النماذج قد يستغرق وقتًا...')));
        await _downloadModels(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ضع نماذج sherpa-onnx في مجلد documents/models')));
        return;
      }
    }

    // If models are present, initialize transcriber
    final models = await _modelsDir();
    final encoder = '${models.path}/encoder.onnx';
    final decoder = '${models.path}/decoder.onnx';
    final joiner = '${models.path}/joiner.onnx';
    final tokens = '${models.path}/tokens.txt';

    try {
      // The exact constructor / API depends on sherpa_onnx package version.
      // Below is a generic example — adjust if the package uses different names.
      _transcriber = SherpaOnnxRecognize(
        encoderModelPath: encoder,
        decoderModelPath: decoder,
        joinerModelPath: joiner,
        tokensPath: tokens,
      );
    } catch (e) {
      // If the package uses a different API, you'll need to adapt here.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تهيئة Sherpa: $e')));
    }
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/zajil_rec_${DateTime.now().millisecondsSinceEpoch}.wav';
      // Record as PCM16 WAV at 16 kHz if supported
      await _recorder.start(path: filePath, encoder: AudioEncoder.pcm16, bitRate: 16000, samplingRate: 16000);
      setState(() {
        _isRecording = true;
        _recordedFilePath = null;
        _transcription = '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد إذن لتسجيل ��لصوت')));
    }
  }

  Future<void> _stopRecording(BuildContext context) async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
      _transcription = '';
    });

    if (path != null) {
      // Ensure transcriber ready
      await _initTranscriberIfReady(context);
      if (_transcriber == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المحوّل غير جاهز. تأكد من وجود النماذج')));
        return;
      }

      // Read file bytes and send to transcriber
      try {
        final bytes = await File(path).readAsBytes();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري تحويل الكلام إلى نص...')));

        // The exact API varies. Here we assume a method `transcribe` that accepts bytes and sampleRate.
        final result = await _transcriber!.transcribe(bytes, sampleRate: 16000);
        setState(() {
          _transcription = result.text ?? '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التحويل: $e')));
      }
    }
  }

  void _openAddOrderModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0B1020),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('إضافة طلب جديد', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Choose method
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (_isRecording) {
                              await _stopRecording(context);
                            } else {
                              await _startRecording();
                            }
                            setState(() {});
                          },
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.black),
                          label: Text(_isRecording ? 'إيقاف التسجيل' : 'تسجيل صوتي', style: const TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Switch to manual form below by scrolling
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text('يدوياً'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5DD3)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_recordedFilePath != null) ...[
                    Text('ملف التسجيل: ${_recordedFilePath!.split('/').last}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 4,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF0E1A2B),
                        hintText: 'النسخة المحولة من الصوت...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(text: _transcription),
                      onChanged: (v) => _transcription = v,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Manual order form
                  _OrderForm(
                    drivers: drivers.where((d) => d['hasProfile'] == true).toList(),
                    onSave: (order) {
                      setState(() {
                        orders.add(order);
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الطلب')));
                    },
                    initialNote: _transcription,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('لوحة التحكم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: _openAddOrderModal,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: _buildSideBar(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top stats row
              _buildTopStats(),
              const SizedBox(height: 16),
              // Charts + orders
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildAnalyticsCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _buildOrdersCard()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideBar() {
    return Drawer(
      backgroundColor: const Color(0xFF071026),
      child: Column(
        children: [
          DrawerHeader(
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                const SizedBox(width: 12),
                const Text('صالح', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.dashboard, color: Colors.white70), title: const Text('اللوحة', style: TextStyle(color: Colors.white70))),
          ListTile(leading: const Icon(Icons.list, color: Colors.white70), title: const Text('الطلبات', style: TextStyle(color: Colors.white70))),
          ListTile(leading: const Icon(Icons.person, color: Colors.white70), title: const Text('السائقين', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard('الإيرادات', '30.15K', Colors.pinkAccent),
        ),
        const SizedBox(width: 12),
        Expanded(child: _statCard('الطلبات', '22.4K', Colors.cyan)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('السائقون', '1.2K', Colors.deepPurpleAccent)),
      ],
    );
  }

  Widget _statCard(String title, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold)),
              Icon(Icons.show_chart, color: accent)
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E1726), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحليلات الأداء', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF071226), borderRadius: BorderRadius.circular(12)),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(spots: [
                            FlSpot(0, 3),
                            FlSpot(1, 2.5),
                            FlSpot(2, 3.5),
                            FlSpot(3, 2),
                            FlSpot(4, 4),
                            FlSpot(5, 3.8),
                          ], isCurved: true, colors: [Colors.cyanAccent], barWidth: 3),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF071226), borderRadius: BorderRadius.circular(12)),
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(5, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (i + 1) * 2.0, color: Colors.purpleAccent, width: 8)])),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 60,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF071226), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _miniStat('نسبة التوصيل', '92%', Colors.greenAccent),
                            _miniStat('متوسط الوقت', '22m', Colors.orangeAccent),
                            _miniStat('إلغاء', '1.5%', Colors.redAccent),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF071226), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الطلبات الحديثة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _openAddOrderModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة طلب جديد'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5DD3)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length == 0 ? 5 : orders.length,
              itemBuilder: (context, index) {
                if (orders.isEmpty) {
                  // placeholder rows
                  return _orderTile(
                    id: '#SKTG23${index}',
                    driverName: 'أحمد محمد',
                    amount: '\$${100 + index * 10}',
                    status: index % 2 == 0 ? 'مكتمل' : 'قيد التنفيذ',
                  );
                }

                final o = orders[index];
                return _orderTile(id: o['id'], driverName: o['driverName'], amount: o['amount'], status: o['status']);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _orderTile({required String id, required String driverName, required String amount, required String status}) {
    return Card(
      color: const Color(0xFF0E1A2B),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12')),
        title: Text(id, style: const TextStyle(color: Colors.white)),
        subtitle: Text(driverName, style: const TextStyle(color: Colors.white70)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: status == 'مكتمل' ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(12)),
              child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }
}

// Small widget: order form used in modal
class _OrderForm extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final ValueChanged<Map<String, dynamic>> onSave;
  final String initialNote;

  const _OrderForm({required this.drivers, required this.onSave, this.initialNote = '', super.key});

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDriverId;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    _noteController.text = widget.initialNote;
    if (widget.drivers.isNotEmpty) _selectedDriverId = widget.drivers.first['id'];
    super.initState();
  }

  @override
  void dispose() {
    _idController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final driver = widget.drivers.firstWhere((d) => d['id'] == _selectedDriverId);
      final order = {
        'id': _idController.text.isEmpty ? '#SKTG${DateTime.now().millisecondsSinceEpoch % 10000}' : _idController.text,
        'driverId': driver['id'],
        'driverName': driver['name'],
        'amount': _amountController.text.isEmpty ? '\$0' : '\$${_amountController.text}',
        'status': 'قيد التنفيذ',
        'note': _noteController.text,
      };
      widget.onSave(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('تفاصيل الطلب', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _idController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'رقم الطلب (اختياري)',
              labelStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF071226),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              labelStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF071226),
              border: InputBorder.none,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال المبلغ' : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDriverId,
            dropdownColor: const Color(0xFF071226),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF071226),
              border: InputBorder.none,
            ),
            items: widget.drivers.map((d) {
              return DropdownMenuItem<String>(value: d['id'], child: Text(d['name']));
            }).toList(),
            onChanged: (v) => setState(() => _selectedDriverId = v),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _noteController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'ملاحظات (يمكن تحرير النص المحول)',
              labelStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Color(0xFF071226),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5DD3)),
              child: const Text('حفظ الطلب'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
