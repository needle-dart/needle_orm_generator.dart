import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';

import 'src/domain.dart';

final log = Logger('Main');
late DataSource globalDs;
void main() async {
  Logger.root.level = Level.FINE; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
  });

  var settings = ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'needle',
      password: 'needle',
      db: 'needle');
  var conn = await MySqlConnection.connect(settings);

  globalDs = MariaDbDataSource(conn); // used in domain.dart
  await test();

  exit(0);
}

Future<void> test2() async {
  var existBooks = [Book()..id = 150];
  var books =
      await Book.Query.findByIds([1, 15, 16, 150], existModeList: existBooks);
  log.info('books list: $books');
  bool reused = books.any((book1) => existBooks.any((book2) => book1 == book2));
  log.info('reused: $reused');
  log.info('books: ${books.map((e) => e.toMap()).toList()}');
}

Future<void> test() async {
  /* var user = User();

  user
    ..name = 'administrator'
    ..address = 'China Shanghai Pudong'
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
    ..price = 11.4
    ..title = 'Dart';
  await book.insert();
  log.info('== 2: book saved , id: ${book.id}');

  var all = await Book.Query.findList();
  log.info('list is:');
  log.info(all.map((e) => e.toMap()).toList()); */

  // just a demo for how to use query:
  var q = Book.Query
    ..title.startsWith('Dart')
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

  log.info('List without nulls: ${books.length}');

  // log.info('=======trigger loading users ==========');
  // log.info('address: ${(books[0] as Book).author?.address}');

  books
      .map((e) => e.toMap(fields: 'title,price,author(id,address)'))
      .forEach(log.info);
  // log.info('List with nulls:');
  // books.map((e) => e.toMap(ignoreNull: false)).forEach(log.info);
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
