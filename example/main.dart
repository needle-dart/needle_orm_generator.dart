import 'dart:async';

import 'package:needle_orm/needle_orm.dart';
import 'package:scope/scope.dart';

import 'src/domain.dart';

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

void main() {
  DataSource ds = MockDataSource();
  (Scope()..value<DataSource>(scopeKeyDefaultDs, ds)).run(test);
}

void main2() {
  final v = Vector(2, 3);
  final w = Vector(2, 2);

  assert(v + w == Vector(4, 5));
  assert(v - w == Vector(0, 1));
  print(v < w == Vector(6, 7));
  print(v < w);
}

class Vector {
  final int x, y;

  Vector(this.x, this.y);

  Vector operator +(Vector v) => Vector(x + v.x, y + v.y);
  Vector operator -(Vector v) => Vector(x - v.x, y - v.y);

  Vector operator <(Vector v) => Vector(x + 2 * v.x, y + 2 * v.y);

  // Operator == and hashCode not shown.
  // ···
  @override
  int get hashCode => Object.hash(x, y);

  @override
  bool operator ==(dynamic other) {
    return other is Vector && other.x == x && other.y == y;
  }

  @override
  String toString() {
    return "Vector[x=$x,y=$y]";
  }
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
