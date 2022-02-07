import 'package:needle_orm/needle_orm.dart';
import 'package:scope/scope.dart';

import 'src/domain.dart';

class MockDataSource extends DataSource {
  MockDataSource() : super(DatabaseType.PostgreSQL, '10.0');
  @override
  Future<List<List>> execute(
      String tableName, String sql, Map<String, dynamic> substitutionValues,
      [List<String> returningFields = const []]) async {
    // print('sql: $sql');
    return List<List>.empty();
    // throw UnimplementedError();
  }
}

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
}
