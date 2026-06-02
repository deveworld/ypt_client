import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../main.dart' show kBrand;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고 배지
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kBrand, Color(0xFFF08A3E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: kBrand.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('YPT',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                ),
                const SizedBox(height: 2),
                Center(
                    child: Text('Yeolpumta Desktop',
                        style: TextStyle(color: Colors.grey[500]))),
                const SizedBox(height: 36),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                      labelText: 'Account (email)',
                      prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pw,
                  obscureText: true,
                  onSubmitted: (_) => _submit(st),
                  decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 10),
                if (st.errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(st.errorText!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13)),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: st.loading ? null : () => _submit(st),
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: st.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Sign in',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Sign in with your YPT account (email signup)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(AppState st) {
    if (_email.text.isEmpty || _pw.text.isEmpty) return;
    st.login(_email.text.trim(), _pw.text);
  }
}
