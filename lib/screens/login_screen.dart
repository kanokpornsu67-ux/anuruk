import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'internal_shell.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  String? _error;

  void _submit() {
    final err = context.read<AppState>().login(_user.text, _pass.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InternalShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบจัดการชมรม')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Image(image: AssetImage('assets/images/logo.png'), width: 100),
                  const SizedBox(height: 8),
                  Text('ยินดีต้อนรับ', style: GoogleFonts.sarabun(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('เฉพาะสมาชิกในชมรม', style: GoogleFonts.sarabun(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _user,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ใช้',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่านชมรม',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kGreen),
                      onPressed: _submit,
                      child: const Text('เข้าสู่ระบบ'),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}