import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../social_auth.dart';
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
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 18),
                // 구분선 "or"
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey[800])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[800])),
                ]),
                const SizedBox(height: 16),
                // 소셜 로그인 (실제 앱과 동일한 공급자/엔드포인트)
                _SocialButton(
                  label: 'Continue with Kakao',
                  bg: const Color(0xFFFEE500),
                  fg: const Color(0xFF191600),
                  icon: Icons.chat_bubble,
                  enabled: !kIsWeb && !st.loading,
                  onTap: () => st.socialLogin(SocialProvider.kakao),
                ),
                const SizedBox(height: 10),
                _SocialButton(
                  label: 'Continue with Naver',
                  bg: const Color(0xFF03C75A),
                  fg: Colors.white,
                  icon: Icons.navigation,
                  enabled: !kIsWeb && !st.loading,
                  onTap: () => st.socialLogin(SocialProvider.naver),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                      kIsWeb
                          ? 'Social login (Kakao/Naver) is available in the desktop app only'
                          : 'Email or Kakao/Naver — your real YPT account',
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

/// 공급자별 색을 가진 소셜 로그인 버튼.
class _SocialButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18, color: fg),
      label: Text(label,
          style: TextStyle(
              color: fg, fontSize: 15, fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: bg.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
