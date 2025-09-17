// post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/db.dart'; // AppDB 경로에 맞게

class PostDetailPage extends StatefulWidget {
  final int postId;
  final String htmlContent;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.htmlContent,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  List<Map<String, dynamic>> _comments = [];
  final _authorCtl = TextEditingController(text: 'guest');
  final _commentCtl = TextEditingController();
  bool _loading = true;

  /// 댓글을 JS 실행(WebView)로 렌더할지 여부 (기본: 꺼짐 — 안전)
  bool _jsMode = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _authorCtl.dispose();
    _commentCtl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final rows = await AppDB.getCommentsForPost(widget.postId);
    if (!mounted) return;
    setState(() {
      _comments = rows;
      _loading = false;
    });
  }

  Future<void> _submitComment() async {
    final author = _authorCtl.text.trim().isEmpty
        ? 'guest'
        : _authorCtl.text.trim();
    final comment = _commentCtl.text.trim();
    if (comment.isEmpty) return;
    await AppDB.insertComment(widget.postId, author, comment);
    _commentCtl.clear();
    await _loadComments();
  }

  /// 댓글 전체를 합쳐 WebView 하나로 띄우기 (성능 우수 / JS 실행)
  void _openCommentsInWebView() {
    final buffer = StringBuffer();
    buffer.writeln(
      '<!doctype html><html><head>'
      '<meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    );
    buffer.writeln('''
      <script>
        // alert/confirm/prompt를 Flutter로 포워딩
        window.alert = function(msg){ try { AlertChannel.postMessage(String(msg)); } catch(_){} };
        window.confirm = function(msg){ try { AlertChannel.postMessage("confirm: " + String(msg)); } catch(_){} return true; };
        window.prompt = function(msg, defVal){ try { AlertChannel.postMessage("prompt: " + String(msg)); } catch(_){} return defVal || ""; };
      </script>
    ''');
    buffer.writeln('</head><body>');
    buffer.writeln('<h3>Comments for Post ${widget.postId}</h3>');
    for (final c in _comments) {
      final author = c['author'] ?? 'guest';
      final created = c['created_at'] ?? '';
      final content = c['comment'] ?? '';
      buffer.writeln(
        '<div style="padding:8px;border-bottom:1px solid #ddd;margin-bottom:6px;">'
        '<strong>${_escapeHtml(author)}</strong> '
        '<small style="color:#666">${_escapeHtml(created)}</small>'
        '<div style="margin-top:6px;">$content</div>' // 의도적으로 인코딩하지 않음(테스트)
        '</div>',
      );
    }
    buffer.writeln('</body></html>');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CommentsWebViewPage(htmlContent: buffer.toString()),
      ),
    );
  }

  String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  @override
  Widget build(BuildContext context) {
    final hasComments = _comments.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('포스트'),
        actions: [
          // JS 실행모드 토글
          Row(
            children: [
              const Text('JS 실행모드', style: TextStyle(fontSize: 12)),
              Switch(
                value: _jsMode,
                onChanged: (v) => setState(() => _jsMode = v),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: '댓글 전체 WebView로 열기 (JS enabled)',
            onPressed: hasComments ? _openCommentsInWebView : null,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadComments),
        ],
      ),
      body: Column(
        children: [
          // 게시글 본문 (HtmlWidget: 안전 렌더)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: HtmlWidget(widget.htmlContent),
            ),
          ),
          const Divider(height: 1),
          // 댓글 영역
          Expanded(
            flex: 3,
            child: Column(
              children: [
                if (_loading) const LinearProgressIndicator(),
                Expanded(
                  child: hasComments
                      ? ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            final author = (c['author'] ?? 'guest') as String;
                            final created = (c['created_at'] ?? '') as String;
                            final html = (c['comment'] ?? '') as String;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          author,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          created,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // 🔒 안전모드: HtmlWidget (JS 미실행)
                                    // 🔓 JS모드: 댓글마다 WebView 렌더 (JS 실행)
                                    _jsMode
                                        ? SizedBox(
                                            height: 180, // 필요 시 조절 (200~300)
                                            child: CommentWebView(html: html),
                                          )
                                        : HtmlWidget(html),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(child: Text('댓글이 없습니다. 첫 댓글을 달아보세요.')),
                ),

                // 댓글 입력
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _authorCtl,
                          decoration: const InputDecoration(
                            labelText: '작성자',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commentCtl,
                          decoration: const InputDecoration(
                            labelText: '댓글 입력 (HTML 허용: 테스트용)',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitComment,
                        child: const Text('전송'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 댓글 하나를 WebView로 렌더하여 JS를 즉시 실행하는 위젯 (테스트 전용)
class CommentWebView extends StatefulWidget {
  final String html;
  const CommentWebView({super.key, required this.html});

  @override
  State<CommentWebView> createState() => _CommentWebViewState();
}

class _CommentWebViewState extends State<CommentWebView> {
  late final WebViewController _ctl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _ctl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AlertChannel',
        onMessageReceived: (m) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('JS alert (comment)'),
              content: Text(m.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (req) {
            // 외부 http/https 링크는 차단 (테스트 안전)
            if (req.url.startsWith('http') || req.url.startsWith('https')) {
              return NavigationDecision.prevent;
            }
            // javascript: 링크를 직접 실행하고 네비게이션은 막기 (선택)
            if (req.url.startsWith('javascript:')) {
              final js = req.url.substring('javascript:'.length);
              _ctl.runJavaScript(js);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    final htmlDoc =
        '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8"> 
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <style>
      body { font-family: -apple-system, Roboto, Segoe UI, sans-serif; margin: 0; padding: 8px; }
      img { max-width: 100%; height: auto; }
    </style>
    <script>
      // alert/confirm/prompt를 Flutter 채널로 포워딩
      window.alert = function(msg){ AlertChannel.postMessage(String(msg)); };
      window.confirm = function(msg){ AlertChannel.postMessage("confirm: " + String(msg)); return true; };
      window.prompt = function(msg, def){ AlertChannel.postMessage("prompt: " + String(msg)); return def || ""; };
    </script>
  </head>
  <body>
    ${widget.html}
  </body>
</html>
''';

    _ctl.loadHtmlString(htmlDoc);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _ctl),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

/// 댓글 전체를 하나의 WebView로 여는 화면 (성능 우수)
class _CommentsWebViewPage extends StatefulWidget {
  final String htmlContent;
  const _CommentsWebViewPage({required this.htmlContent});

  @override
  State<_CommentsWebViewPage> createState() => _CommentsWebViewPageState();
}

class _CommentsWebViewPageState extends State<_CommentsWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AlertChannel',
        onMessageReceived: (msg) {
          _showAlert(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (req) {
            if (req.url.startsWith('http') || req.url.startsWith('https')) {
              return NavigationDecision.prevent;
            }
            if (req.url.startsWith('javascript:')) {
              final js = req.url.substring('javascript:'.length);
              _controller.runJavaScript(js);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
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
      appBar: AppBar(title: const Text('Comments — WebView (JS enabled)')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
