import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('DVWA Mobile — Board (XSS)')),
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
                    await AppDB.instance(); // DB 연결확인
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
                  // 리스트엔 HTML 태그가 그대로 보이면 보기 안좋으니 요약 텍스트로 보여주자
                  final preview = _stripHtmlPreview(content, maxLen: 80);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(preview),
                      subtitle: Text('Tap to view (may execute JS in demo)'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PostDetailPage(htmlContent: content),
                          ),
                        );
                      },
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

  String _stripHtmlPreview(String html, {int maxLen = 80}) {
    // 아주 간단한 HTML 태그 제거(리스트용 미리보기)
    final plain = html.replaceAll(RegExp(r'<[^>]*>'), '');
    if (plain.length <= maxLen) return plain;
    return plain.substring(0, maxLen) + '...';
  }
}

/// 상세보기: WebView로 HTML 로드하고 JS의 alert()를 Flutter 다이얼로그로 포워딩
class PostDetailPage extends StatefulWidget {
  final String htmlContent;
  const PostDetailPage({super.key, required this.htmlContent});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AlertChannel',
        onMessageReceived: (JavaScriptMessage msg) {
          _showAlert(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (req) {
            // 데모 앱에서는 외부 네비게이션을 막아 안전하게 유지 (원하면 조정)
            if (req.url.startsWith('http') || req.url.startsWith('https')) {
              // 외부 링크는 차단(또는 따로 처리)
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    final wrappedHtml =
        '''
    <!doctype html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <style>
          body { font-family: -apple-system, Roboto, "Segoe UI", sans-serif; padding: 12px; }
        </style>
        <script>
          // 브라우저 alert을 Flutter로 포워딩
          window.alert = function(msg) {
            AlertChannel.postMessage(String(msg));
          };
        </script>
      </head>
      <body>
        ${widget.htmlContent}
      </body>
    </html>
    ''';

    _controller.loadHtmlString(wrappedHtml);
  }

  void _showAlert(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('JS alert'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 상세 (WebView)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
