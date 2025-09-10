import 'package:flutter/material.dart';
import '../services/db.dart';
import 'board_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController(text: '');
  final _pw = TextEditingController(text: '');

  String _status = 'Try default: admin / admin';

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  // ❌ 고의적 취약: rawQuery 문자열 결합 → SQLi 가능
  Future<bool> _vulnLogin(String u, String p) async {
    final db = await AppDB.instance();
    final sql = "SELECT * FROM users WHERE username='$u' AND password='$p'";
    final rows = await db.rawQuery(sql);
    return rows.isNotEmpty;
  }

  Future<void> _onLogin() async {
    final ok = await _vulnLogin(_id.text, _pw.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _status = 'Login success ✅');
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const BoardPage()));
    } else {
      setState(() => _status = 'Login failed ❌  (hint: SQLi)');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('DVWA Mobile — Login (SQLi)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_status, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _id,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: "e.g. admin  |  or  ' OR '1'='1",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pw,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'e.g. admin (ignored by SQLi payload)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onLogin,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                // 실습 힌트
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    "💡 SQLi Bypass 예시\n"
                    "username: ' OR '1'='1\n"
                    "password: (아무 값이나)\n\n"
                    "⚠️ 이 앱은 교육/연구용 취약 환경입니다.",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
