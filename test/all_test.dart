import 'dart:async';

import 'package:logging/logging.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:test/test.dart';
import 'src/domain.dart';
import 'common.dart';

void main() async {
  setUp(() async {
    await init();
  });

  tearDown(() async {
    // await globalDs.close();
  });

  test('testCount', testCount);
  test('testInsert', testInsert);
  test('testUpdate', testUpdate);
  test('testFindByIds', testFindByIds);
  test('testInsertBatch', testInsertBatch);
  test('testLoadNestedFields', testLoadNestedFields);
  test('testPaging', testPaging);

  // new Timer(const Duration(seconds: 10), () => exit(0));
}

Future<void> testFindByIds() async {
  var log = Logger('$logPrefix testFindByIds');

  var existBooks = [Book()..id = 4660];
  var books = await Book.Query.findByIds([1, 15, 16, 4660, 4674],
      existModeList: existBooks);
  log.info('books list: $books');
  bool reused = books.any((book1) => existBooks.any((book2) => book1 == book2));
  log.info('reused: $reused');
  log.info('books: ${books.map((e) => e.toMap()).toList()}');
}

Future<void> testCount() async {
  var log = Logger('$logPrefix testCount');
  log.info(await Book.Query.count());
}

Future<void> testInsert() async {
  var log = Logger('$logPrefix testInsert');

  log.info('count before insert : ${await Book.Query.count()}');
  var n = 5;
  for (int i = 0; i < n; i++) {
    var user = User()
      ..name = 'name_$i'
      ..address = 'China Shanghai street_$i'
      ..age = (n * 0.1).toInt();
    await user.save();
    log.info('\t used saved with id: ${user.id}');

    var book = Book()
      ..author = user
      ..price = n * 0.3
      ..title = 'Dart$i';
    await book.insert();
    log.info('\t book saved with id: ${book.id}');
  }
  log.info('count after insert : ${await Book.Query.count()}');
}

Future<void> testInsertBatch() async {
  var log = Logger('$logPrefix testInsertBatch');

  var n = 10;
  var users = <User>[];
  var books = <Book>[];
  for (int i = 0; i < n; i++) {
    var user = User()
      ..name = 'name_$i'
      ..address = 'China Shanghai street_$i'
      ..age = (n * 0.1).toInt();
    users.add(user);

    var book = Book()
      ..author = user
      ..price = n * 0.3
      ..title = 'Dart$i';
    books.add(book);
  }
  log.info('users created');
  await User.Query.insertBatch(users, batchSize: 5);
  log.info('users saved');
  var idList = users.map((e) => e.id).toList();
  log.info('ids: $idList');
}

Future<void> testPaging() async {
  var log = Logger('$logPrefix paging');
  var q = Book.Query
    ..title.startsWith('Dart')
    ..price.between(10.0, 20)
    ..author.apply((author) {
      author
        ..age.ge(18)
        ..address.startsWith('China Shanghai');
    });

  q.orders = [Book.Query.id.desc()];

  {
    q.paging(0, 3);
    var books = await q.findList();
    int total = await q.count();
    log.info('total $total , ids: ${books.map((e) => e.id).toList()}');
  }
  {
    q.paging(1, 3);
    var books = await q.findList();
    int total = await q.count();
    log.info('total $total , ids: ${books.map((e) => e.id).toList()}');
  }
  {
    // prevent paging
    q.paging(0, 0);
    var books = await q.findList();
    int total = await q.count();
    log.info('total $total , ids: ${books.map((e) => e.id).toList()}');
  }
}

Future<void> testUpdate() async {
  var log = Logger('$logPrefix testUpdate');

  var user = User();

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
  user.save(); // update
  log.info('== 2: admin updated, id: ${user.id}');

  var book = Book()
    ..author = user
    ..price = 11.4
    ..title = 'Dart admin';
  await book.insert();
  log.info('== 3: book saved , id: ${book.id}');
}

Future<void> testLoadNestedFields() async {
  var log = Logger('$logPrefix testLoadNestedFields');

  var q = Book.Query
    ..orders = [Book.Query.title.asc()]
    ..maxRows = 2;
  var books = await q.findList();
  var total = await q.count();

  log.info('found books: ${books.length}, total: $total');

  log.info('author.address will be auto loaded from db');
  books
      .map((e) => e.toMap(fields: 'title,price,author(id,address)'))
      .forEach(log.info);
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
