import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';

final logPrefix = 'MainTest';
final log = Logger(logPrefix);
final random = Random();
late Database globalDs;

void main() async {
  globalDs = await initMariaDb();

  final lines = book()..removeWhere((element) => element.isEmpty);

  log.info('book lines : ${lines.length}');

  final allIds = await allDirectoryIds();
  log.info('allIds length: ${allIds.length}');

  final allPids = allIds
      .where((element) => element[1] == 1)
      .map((e) => e[0] as int)
      .toList();
  log.info('allPids length: ${allPids.length}');

  final allClassIds = allIds
      .where((element) => element[1] == 3)
      .map((e) => e[0] as int)
      .toList();
  log.info('allClassIds length: ${allClassIds.length}');

  final imageIds = await allImageIds();

  for (int i = 0; i < 10000; i++) {
    var pid = allPids[random.nextInt(allPids.length)];
    var classId = allClassIds[random.nextInt(allClassIds.length)];
    var imageId = imageIds[random.nextInt(imageIds.length)][0];
    var content = lines[random.nextInt(lines.length)];
    var title = '鲁迅:' + content.substring(0, min(10, content.length));
    await insert(
        pid: pid,
        classId: classId,
        imageId: imageId,
        title: title,
        content: content);
    if (i % 1000 == 0) {
      log.info('inserted rows: $i');
    }
  }
}

List<String> book() {
  return File('/home/tony/lx.txt').readAsLinesSync();
}

Future<DbQueryResult> allDirectoryIds() async {
  final sql = 'select id,app_type from smai_know_directory';
  final result = await globalDs.query(sql, {});
  // log.info('smai_know_directory: $result');
  return result;
}

Future<DbQueryResult> allImageIds() async {
  final sql = 'select sr_id from smai_common_resource';
  final result = await globalDs.query(sql, {});
  // log.info('smai_common_resource: $result');
  return result;
}

// smai_know_know_access_auth
// know_id 从第一条鲁迅开始
// access_type 给个0

Future<DbQueryResult> insert({
  required int pid,
  required int classId,
  required int imageId,
  required String title,
  required String content,
}) async {
  var sql = '''
insert into smai_know_know(pid,class_id,title,content,k_img_id,examine_status,importance_level,create_at,create_user,update_at,update_user)
values(@pid,@class_id,@title,@content,@k_img_id,1,@importance_level,@create_at,1,@update_at,1)
''';
  var params = {
    "pid": pid,
    "class_id": classId,
    'title': title,
    'content': content,
    'importance_level': 1,
    'k_img_id': 1,
    'create_at': 1651022983 + pid,
    'update_at': 1651022983 + pid,
  };
  var result = await globalDs.query(sql, params);
  // log.info(result);
  return result;
}

Future<Database> initMariaDb() async {
  Logger.root.level = Level.INFO; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time} ${record.loggerName}: ${record.message}');
  });

  var settings = ConnectionSettings(
      host: '192.168.1.18',
      port: 3306,
      user: 'xcall',
      password: 'XCall20*#',
      db: 'knowledge');
  var conn = await MySqlConnection.connect(settings);

  return MariaDbDatabase(conn);
}
