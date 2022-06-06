import 'dart:async';
import 'dart:io';

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

  test('general test', () async {
    await testAll();
  });
  test('testFindByIds', () async {
    await testFindByIds();
  });
  test('testCount', () async {
    await testCount();
  });
  test('testInsert', () async {
    await testInsert();
  });
  test('testInsertBatch', () async {
    await testInsertBatch();
  });
  test('testPaging', () async {
    await testPaging();
  });

  // new Timer(const Duration(seconds: 10), () => exit(0));
}

Future<void> testFindByIds() async {
  var existBooks = [Book()..id = 4660];
  var books = await Book.Query.findByIds([1, 15, 16, 4660, 4674],
      existModeList: existBooks);
  log.info('books list: $books');
  bool reused = books.any((book1) => existBooks.any((book2) => book1 == book2));
  log.info('reused: $reused');
  log.info('books: ${books.map((e) => e.toMap()).toList()}');
}

Future<void> testCount() async {
  log.info(await Book.Query.count());
}

Future<void> testInsert() async {
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
  log.info('finished');
}

Future<void> testInsertBatch() async {
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

Future<void> testAll() async {
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

  var book = Book()
    ..author = user
    ..price = 11.4
    ..title = 'Dart';
  await book.insert();
  log.info('== 2: book saved , id: ${book.id}');

  var all = await Book.Query.findList();
  log.info('list is:');
  log.info(all.map((e) => e.toMap()).toList());

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
/* 
  log.info('-------show conditions begin ----------');
  q.columns.forEach((c) {
    debugCondition(c);
  });
  log.info('-------show conditions end ----------');
  log.info('');
 */
  q.orders = [Book.Query.title.asc()];
  q.paging(1, 3);
  var books = await q.findList();

  log.info('found books: ${books.length}');

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
