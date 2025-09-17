import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/db.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});
  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  final _ctl = TextEditingController();
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final db = await AppDB.instance();
    final rows = await db.rawQuery(
      'SELECT id, post FROM posts ORDER BY id DESC',
    );
    setState(() => _posts = rows.cast<Map<String, dynamic>>());
  }

  Future<void> _addPost() async {
    final text = _ctl.text;
    if (text.trim().isEmpty) return;
    final db = await AppDB.instance();
    await db.insert('posts', {'post': text});
    _ctl.clear();
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DVWA Mobile')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _ctl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Write Post Please',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: _addPost, child: const Text("Post")),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await AppDB.instance(); //DB 연결확인
                    await _loadPosts();
                  },
                  child: const Text('새로고침'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (_, i) {
                  final p = _posts[i];
                  final content = p['post'] as String? ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: HtmlWidget(content), //입력 문자열 HTML로 해석
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
