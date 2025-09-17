import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDB {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    try {
      // db 초기화
      final path = join(await getDatabasesPath(), 'vulnapp.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, v) async {
          await db.execute(
            'CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT UNIQUE, password TEXT)',
          );
          await db.execute(
            'CREATE TABLE posts(id INTEGER PRIMARY KEY AUTOINCREMENT, post TEXT)',
          );
          await db.execute(
            'CREATE TABLE files(id INTEGER PRIMARY KEY, file TEXT, path TEXT)',
          );
          await db.execute(
            'CREATE TABLE comments(id INTEGER PRIMARY KEY AUTOINCREMENT, post_id INTEGER, author TEXT, comment TEXT, created_at TEXT)',
          );

          // 의도적으로 취약한 아이디패스워드 입력
          await db.insert('users', {'username': 'admin', 'password': "admin"});
          // 더미 포스트 10개 (HTML 문자열)
          final dummyPosts = [
            """
            <h2>1. 보안 컨설턴트 첫 출근 후기</h2>
            <p>오늘은 드디어 첫 출근! <strong>VPN</strong> 연결부터 사내 계정 세팅까지 정신없었지만, 
            보안팀 선배들이 너무 친절해서 금방 적응할 수 있을 것 같다.</p>
            """,
            """
            <h2>2. Flutter로 만드는 보안 학습 앱</h2>
            <p><em>DVWA Mobile</em>을 직접 만들면서 <u>XSS</u>와 <u>SQL Injection</u> 실습을 할 수 있도록 구성 중이다. 
            디자인은 미니멀하게, 기능은 취약하게! 😂</p>
            """,
            """
            <h2>3. 주말에 읽은 책 추천</h2>
            <p>『해킹: 공격과 방어의 예술』을 다시 꺼내 읽었다. 
            옛날 책이지만 여전히 <span style="color:blue;">기본기</span>를 다지기에 좋아서 추천하고 싶다.</p>
            """,
            """
            <h2>4. 회사 점심 맛집 탐방</h2>
            <p>오늘 점심은 <strong>칼국수집</strong>을 갔는데, 가격도 착하고 양도 푸짐해서 대만족! 
            <img src="https://via.placeholder.com/150x80?text=Noodles" /></p>
            """,
            """
            <h2>5. 모의해킹 과제 후기</h2>
            <p>과제 주제는 <code>SQL Injection</code>. <br>
            파라미터 조작으로 DB 데이터가 그대로 노출되는 걸 확인했을 때 쾌감이란! 😎</p>
            """,
            """
            <h2>6. 사이버 대학 시험 준비</h2>
            <p><mark>시스템보안</mark> 시험은 실제 사례 중심 문제라 단순 정의보다 
            사례를 외우는 게 훨씬 중요하다.</p>
            """,
            """
            <h2>7. 내 기타 톤 세팅 기록</h2>
            <p>요즘 <em>Morning Star</em> 트랙 맞춰 연습 중. <br>
            <ul>
              <li>Gain: 6</li>
              <li>Bass: 4</li>
              <li>Treble: 7</li>
            </ul>
            </p>
            """,
            """
            <h2>8. 업무 중 깨달음</h2>
            <blockquote>
            “로그는 거짓말을 하지 않는다.”
            </blockquote>
            취약점 점검보다 더 중요한 게 바로 로그 분석이라는 걸 다시 느꼈다.
            """,
            """
            <h2>9. 잡생각 메모</h2>
            <p>가끔은 <strong>연구직</strong>으로 가는 게 맞나 싶기도 하고, 
            그냥 지금처럼 <i>컨설팅</i>이 맞나 싶다. <br>
            고민은 늘 현재진행형.</p>
            """,
            """
            <h2>10. 운동 루틴 공유</h2>
            <p>오늘의 3대 운동 기록 💪</p>
            <ol>
              <li>스쿼트 80kg x 5</li>
              <li>벤치프레스 70kg x 5</li>
              <li>데드리프트 100kg x 5</li>
            </ol>
            """,
          ];

          for (final html in dummyPosts) {
            await db.insert('posts', {'post': html});
          }
        },
      );
      print('[DB] 데이터베이스 오픈 완료');
    } catch (e, s) {
      print('[DB] openDatabase 에러: $e');
      print(s);
      rethrow; // 필요하면 다시 던져서 상위에서 처리
    }
    return _db!;
  }

  // 댓글 추가 헬퍼
  static Future<int> insertComment(
    int postId,
    String author,
    String comment,
  ) async {
    final db = await instance();
    final now = DateTime.now().toIso8601String();
    return await db.insert('comments', {
      'post_id': postId,
      'author': author,
      'comment': comment,
      'created_at': now,
    });
  }

  // 포스트별 댓글 조회
  static Future<List<Map<String, dynamic>>> getCommentsForPost(
    int postId,
  ) async {
    final db = await instance();
    final rows = await db.query(
      'comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'id ASC',
    );
    return rows;
  }
}
