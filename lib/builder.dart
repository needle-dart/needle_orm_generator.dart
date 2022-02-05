import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/orm_generator.dart';

Builder ormGenerator(BuilderOptions options) =>
    SharedPartBuilder([OrmGenerator()], 'needle_orm');
