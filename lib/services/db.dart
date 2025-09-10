import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDB {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    // db 초기화
    final path = join(await getDatabasesPath(), 'vulnapp.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY,user TEXT UNUQUE, password TEXT)',
        );
        await db.execute(
          'CREATE TABLE posts(id INTEGER PRIMARY KEY, password TEXT)',
        );
        await db.execute(
          'CREATE TABLE files(id INTEGER PRIMARY KEY,file TEXT, path TEXT)',
        );
        // 의도적으로 취약한 아이디패스워드 입력
        await db.insert('users', {'username': 'admin', 'password': "admin"});
      },
    );
    return _db!;
  }
}
