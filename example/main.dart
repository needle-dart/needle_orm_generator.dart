import 'src/domain.dart';

void main() {
  var user = User();
  user
    ..name = 'someone'
    ..address = 'abc'
    ..age = 23
    ..save(); // insert

  print(user.toString());

  user
    ..id = 100
    ..save(); // update

  print(user.toString());
  print('is admin? ${user.isAdmin()}');

  var book = Book();
  book
    ..author = user
    ..title = 'Dart'
    ..insert();
}
