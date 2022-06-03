import 'dart:async';

import 'package:loggy/loggy.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:scope/scope.dart';

import 'src/domain.dart';

var log = Loggy("main");

void main() {
  Loggy.initLoggy(
    logPrinter: const PrettyPrinter(),
  );

  log.info('start');
  DataSource ds = MockDataSource();
  (Scope()..value<DataSource>(scopeKeyDefaultDs, ds)).run(test);
}

void test() async {
  var user = User();

  user
    ..name = 'administrator'
    ..address = 'abc'
    ..age = 23
    ..save(); // insert

  user
    ..id = 100
    ..save(); // update because id is set.

  // call business method
  // print('========== logger? $logger');
  // logger.i('is admin? ${user.isAdmin()}');
  log.info('user.toMap() : ${user.toMap()}');

  // load data from a map
  user.loadMap({"name": 'admin123', "xxxx": 'xxxx'});

  Book()
    ..author = user
    ..title = 'Dart'
    ..insert();

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
