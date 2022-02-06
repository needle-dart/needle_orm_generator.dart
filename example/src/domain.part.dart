part of 'domain.dart';

// can write business logic here.

extension BizUser on User {
  bool isAdmin() {
    return name!.startsWith('admin');
  }

  // specified in @Entity(beforeInsert:'beforeInsert') because override is not possible now, see: https://github.com/dart-lang/language/issues/177
  // @override
  void beforeInsert() {
    _version = 1;
    _deleted = false;
    print('before insert user ....');
  }

  void afterInsert() {
    print('after insert user ....');
  }
}
