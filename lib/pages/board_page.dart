import 'package:flutter/material.dart';

class BoardPage extends StatelessWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DVWA Mobile — Board (XSS next)')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '로그인 성공!\n\n여기는 2장(XSS)에서 게시판 기능을 붙일 화면입니다.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
