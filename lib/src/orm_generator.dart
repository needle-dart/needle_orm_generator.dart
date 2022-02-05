import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:source_gen/source_gen.dart';

class OrmGenerator extends GeneratorForAnnotation<OrmAnnotation> {
  bool commonAdded = false;

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw 'The top @OrmAnnotation() annotation can only be applied to classes.';
    }
    if (!commonAdded) {
      commonAdded = true;
      return ClassInspector(element, true).generate();
    }
    return ClassInspector(element, false).generate();
  }
}

class FieldInspector {
  final FieldElement fieldElement;
  String name;

  FieldInspector(this.fieldElement) : name = fieldElement.name {
    if (name.startsWith('_')) {
      name = name.substring(1);
    }
  }

  String generate() {
    var type = fieldElement.type.toString();
    if (type.startsWith('_')) {
      type = type.substring(1);
    }
    return '''
  $type _$name ;
  $type get $name => _$name;
  set $name($type v) {
    _$name = v;
    __dirtyMap['_$name'] = true;
  }
''';
  }
}

class ClassInspector {
  final ClassElement classElement;
  final bool first;
  String name;

  ClassElement? superClassElement;
  String? superName;

  bool topClass = true;
  List<FieldElement> fields = [];

  ClassInspector(this.classElement, this.first) : name = classElement.name {
    if (classElement.supertype != null &&
        classElement.supertype!.element.name != 'Object') {
      superClassElement = classElement.supertype!.element;
      superName = superClassElement!.name;
      topClass = false;
    }
    if (name.startsWith('_')) {
      name = name.substring(1);
    }
    if (superName != null && superName!.startsWith('_')) {
      superName = superName!.substring(1);
    }
  }

  String generate() {
    var fields =
        classElement.fields.map((f) => FieldInspector(f).generate()).join('\n');

    var prefix = first ? common : "";

    var _superClassName = topClass ? "__Model" : superName;

    var _abstract = classElement.isAbstract ? "abstract" : "";
    return '''
    $prefix
    $_abstract class $name extends $_superClassName { 

      $fields

      $name(); 

      ${defFunGetField(classElement)}

      String? __getIdFieldName(){
        return "_id";
      }

    }''';
  }

  String defFunGetField(ClassElement clazz) {
    var defaultStmt = topClass
        ? "throw 'class ${clazz.name} has now such field: \$fieldName'"
        : "return super.__getField(fieldName)";
    return '''
  dynamic __getField(String fieldName) {
    switch (fieldName) {
      ${clazz.fields.map((e) => 'case "${e.name}": return ${e.name};').join('\n')} 
      default: $defaultStmt ;
    }
  }''';
  }

  static const common = '''
abstract class __Model {
  final __dirtyMap = <String, bool>{};

  //abstract
  dynamic __getField(String fieldName);
  
  //abstract
  String? __getIdFieldName();

  void __cleanDirty() {
    __dirtyMap.clear();
  }

  String toString() {
    return __dirtyMap.keys.map((e) => "\$e:\${__getField(e)}").join(",");
  }

  void insert() {
    print('insert ...');
  }

  void update() {
    print('update ...');
  }

  void save() {
    var idName = __getIdFieldName();
    if (idName == null) throw 'no @ID field';

    if (__getField(idName) != null) {
      update();
    } else {
      insert();
    }
  }

  void delete() {
    print('delete ...');
  }

  void deletePermant() {
    print('deletePermant ...');
  }
}
''';
}
