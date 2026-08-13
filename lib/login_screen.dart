import 'package:flutter/material.dart';

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
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Center(child: Text('تم تسجيل الدخول'))));
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
