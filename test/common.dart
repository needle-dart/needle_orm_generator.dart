import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_mariadb/needle_orm_mariadb.dart';
import 'package:needle_orm_postgres/needle_orm_postgres.dart';
import 'package:postgres_pool/postgres_pool.dart';

final logPrefix = 'MainTest';
final log = Logger(logPrefix);
late Database globalDs;

Future<Database> initMariaDb() async {
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

  return MariaDbDataSource(conn); // used in domain.dart
}

Future<Database> initPostgreSQL() async {
  return PostgreSqlPoolDataSource(PgPool(
    PgEndpoint(
      host: 'localhost',
      port: 5432,
      database: 'appdb',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: PgPoolSettings()
      ..maxConnectionAge = Duration(hours: 1)
      ..concurrency = 5,
  ));
}
