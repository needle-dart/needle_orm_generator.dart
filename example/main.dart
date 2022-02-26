import 'dart:async';

import 'package:needle_orm/needle_orm.dart';
import 'package:scope/scope.dart';

import 'src/domain.dart';

void main() {
  DataSource ds = MockDataSource();
  (Scope()..value<DataSource>(scopeKeyDefaultDs, ds)).run(test);
}

void test() {
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
  print('is admin? ${user.isAdmin()}');
  print('user.toMap() : ${user.toMap()}');

  // load data from a map
  user.loadMap({"name": 'admin123', "xxxx": 'xxxx'});

  Book()
    ..author = user
    ..title = 'Dart'
    ..insert();

  Book.Query.findAll();

/* 
  Book.Query
        ..name ~ 'dart'
        ..age > 10
        ..(author..name = 'john'
                 ..age > 30)
 */
}

class MockDataSource extends DataSource {
  MockDataSource() : super(DatabaseType.PostgreSQL, '10.0');
  @override
  Future<List<List>> execute(
      String tableName, String sql, Map<String, dynamic> substitutionValues,
      [List<String> returningFields = const []]) async {
    print('[sql] $sql [bindings: $substitutionValues]');
    return List<List>.empty();
    // throw UnimplementedError();
  }

  @override
  Future<T> transaction<T>(FutureOr<T> Function(DataSource p1) f) {
    throw UnimplementedError();
  }
}
