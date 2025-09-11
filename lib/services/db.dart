import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDB {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
  
    try{
      // db 초기화
      final path = join(await getDatabasesPath(), 'vulnapp.db');
      _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
          await db.execute(
           'CREATE TABLE users(id INTEGER PRIMARY KEY,username TEXT UNIQUE, password TEXT)',
          );
          await db.execute(
            'CREATE TABLE posts(id INTEGER PRIMARY KEY, post TEXT)',
          );
          await db.execute(
            'CREATE TABLE files(id INTEGER PRIMARY KEY,file TEXT, path TEXT)',
          );
          // 의도적으로 취약한 아이디패스워드 입력
          await db.insert('users', {'username': 'admin', 'password': "admin"});
        });
      print('[DB] 데이터베이스 오픈 완료');
    }catch (e, s) {
      print('[DB] openDatabase 에러: $e');
      print(s);
      rethrow; // 필요하면 다시 던져서 상위에서 처리
    }
    return _db!; 
  }
}

