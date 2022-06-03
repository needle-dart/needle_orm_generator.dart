part of 'domain.dart';

// can write business logic here.

extension BizUser on User {
  static Loggy _logger = Loggy('USER');
  bool isAdmin() {
    return name!.startsWith('admin');
  }

  // specified in @Entity(prePersist: 'beforeInsert', postPersist: 'afterInsert') because override is not possible now, see: https://github.com/dart-lang/language/issues/177
  // @override
  void beforeInsert() {
    _version = 1;
    _deleted = false;
    _logger.info('before insert user ....');
  }

  void afterInsert() {
    _logger.info('after insert user ....');
  }
}
