part of 'domain.dart';

// can write business logic here.

extension BizUser on User {
  bool isAdmin() {
    return name!.startsWith('admin');
  }
}
