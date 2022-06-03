import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';

import 'src/domain.dart';

final log = Logger('GeneratorExample');
late DataSource globalDs;
void main() async {
  Logger.root.level = Level.INFO; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
  });

  var settings = new ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'needle',
      password: 'needle',
      db: 'needle');
  var conn = await MySqlConnection.connect(settings);
/* 
  var result = await conn.query(
      "insert into users (name, email, age, created_at) values (?, ?, ?, 'now()')",
      ['Bob', 'bob@bob.com', 25]); 
  */

  // DataSource ds = MockDataSource();
  DataSource ds = MariaDbDataSource(conn);
  globalDs = ds;
  // (Scope()..value<DataSource>(scopeKeyDefaultDs, ds)).run(test);
  await test();
}

Future<void> test() async {
  var user = User();

  user
    ..name = 'administrator'
    ..address = 'abc'
    ..age = 23;

  await user.save(); // insert

  log.info('== 1: admin saved , id: ${user.id}');

  // call business method
  log.info('is admin? ${user.isAdmin()}');
  log.info('user.toMap() : ${user.toMap()}');

  // load data from a map
  user.loadMap({"name": 'admin123', "xxxx": 'xxxx'});

  var book = Book()
    ..author = user
    ..title = 'Dart';
  await book.insert();
  log.info('== 2: book saved , id: ${book.id}');

  if (1 == 1) exit(0);

  var all = await Book.Query.findList();
  log.info('list is:');
  log.info(all.map((e) => e.toMap()).toList());

  // just a demo for how to use query:
  var q = Book.Query
    ..title.startsWith('dart')
    ..price.between(10.0, 20)
    ..author.apply((author) {
      author
        ..age.ge(18)
        ..address.startsWith('China Shanghai');
    });

  log.info('');
  log.info('-------show conditions begin ----------');
  q.columns.forEach((c) {
    debugCondition(c);
  });
  log.info('-------show conditions end ----------');
  log.info('');

  // q.findAll();
  var books = await q.findList();

  log.info('List without nulls:');
  books.map((e) => e.toMap()).forEach(log.info);
  log.info('List with nulls:');
  books.map((e) => e.toMap(ignoreNull: false)).forEach(log.info);

  exit(0);
}

debugCondition(c) {
  if (c is ColumnQuery) {
    c.conditions.forEach(log.info);
  } else if (c is BaseModelQuery) {
    if (cache.contains(c)) {
      // prevent circle reference
      return;
    }
    cache.add(c);
    c.columns.forEach((element) {
      debugCondition(element);
    });
  }
}

Set<BaseModelQuery> cache = {};

class MockDataSource extends DataSource {
  MockDataSource() : super(DatabaseType.PostgreSQL, '10.0');
  @override
  Future<List<List>> execute(
      String tableName, String sql, Map<String, dynamic> substitutionValues,
      [List<String> returningFields = const []]) async {
    log.info(
        '[sql] [$tableName] $sql [bindings: $substitutionValues] [return: $returningFields]');
    if (tableName == 'books') return _mockBook();
    return List<List>.empty();
    // throw UnimplementedError();
  }

  List<List> _mockBook() {
    return [
      ['Dart', 15.0, 200, 100, 1, false]
    ];
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(DataSource p1) f) {
    throw UnimplementedError();
  }
}
