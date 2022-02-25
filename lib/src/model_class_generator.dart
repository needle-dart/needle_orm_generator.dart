import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:needle_orm_generator/src/common.dart';
import 'package:source_gen/source_gen.dart';
import 'helper.dart';

class NeedleOrmModelGenerator extends GeneratorForAnnotation<Entity> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw 'The top @OrmAnnotation() annotation can only be applied to classes.';
    }
    return ClassInspector(element, annotation).generate();
  }
}

class FieldInspector {
  final FieldElement fieldElement;
  String name;
  List<OrmAnnotation> ormAnnotations = [];

  FieldInspector(this.fieldElement) : name = fieldElement.name.removePrefix() {
    handleAnnotations(fieldElement);
  }

  void handleAnnotations(FieldElement ce) {
    ce.metadata.forEach((annot) {
      var name = annot.name;
      switch (name) {
        case 'DbComment':
          ormAnnotations.add(annot.toDbComment());
          break;
        case 'Column':
          ormAnnotations.add(annot.toColumn());
          break;
        case 'ID':
          ormAnnotations.add(ID());
          break;
        case 'Lob':
          ormAnnotations.add(Lob());
          break;
        case 'Version':
          ormAnnotations.add(Version());
          break;
        case 'SoftDelete':
          ormAnnotations.add(SoftDelete());
          break;
        case 'WhenCreated':
          ormAnnotations.add(WhenCreated());
          break;
        case 'WhenModified':
          ormAnnotations.add(WhenModified());
          break;
        case 'WhoCreated':
          ormAnnotations.add(WhoCreated());
          break;
        case 'WhoModified':
          ormAnnotations.add(WhoModified());
          break;
      }
    });
  }

  String generate() {
    var type = fieldElement.type.toString().removePrefix();

    return '''
      $type _$name ;
      $type get $name => _$name;
      set $name($type v) {
        _$name = v;
        __markDirty('$name');
      }
    ''';
  }
}

class ClassInspector {
  final ClassElement classElement;
  String name;

  late String tableName;
  ClassElement? superClassElement;
  String? superClassName;
  List<OrmAnnotation> ormAnnotations = [];
  late Entity entity;

  bool isTopClass = true;
  List<FieldElement> fields = [];

  ClassInspector(this.classElement, ConstantReader annotation)
      : name = classElement.name.removePrefix() {
    if (classElement.supertype != null &&
        classElement.supertype!.element.name != 'Object') {
      superClassElement = classElement.supertype!.element;
      superClassName = superClassElement!.name.removePrefix();
      isTopClass = false;
    }

    handleAnnotations(this.classElement);

    this.entity = this.ormAnnotations.whereType<Entity>().first;

    tableName = name.toLowerCase();
  }

  void handleAnnotations(ClassElement ce) {
    ce.metadata.forEach((annot) {
      var name = annot.name;
      switch (name) {
        case 'Entity':
          ormAnnotations.add(annot.toEntity());
          break;
      }
    });
  }

  String generate() {
    var fields =
        classElement.fields.map((f) => FieldInspector(f).generate()).join('\n');

    var _superClassName = isTopClass ? "__Model" : superClassName;

    var _abstract = classElement.isAbstract ? "abstract" : "";
    return '''
    ${genModelQuery()}

    $_abstract class $name extends $_superClassName { 

      $fields

      $name(); 

      static ${name}ModelQuery get Query => ${name}ModelQuery();

      ${overrideGetField(classElement)}
      ${overrideSetField(classElement)}

      ${overrideToMap(classElement)}

      @override
      String get __tableName {
        return "$tableName";
      }

      @override
      String? get __idFieldName{
        return "id";
      }

      ${overrideprePersist()}
      ${overridepreUpdate()}
      ${overridepreRemove()}
      ${overridepreRemovePermanent()}
      ${overridepostPersist()}
      ${overridepostUpdate()}
      ${overridepostRemove()}
      ${overridepostRemovePermanent()}
      ${overridepostLoad()}

    }''';
  }

  String genModelQuery() {
    return '''
      class ${name}ModelQuery extends _BaseModelQuery<$name, int> {
        @override
        String get className => '$name';
      }
      ''';
  }

  String overrideEvent(String eventType, String eventHandler) {
    return '''
      @override void __${eventType}() {
        ${eventHandler}();
      }
      ''';
  }

  String overridepostLoad() {
    if (entity.postLoad == null) {
      return '';
    }
    return overrideEvent('postLoad', entity.postLoad!);
  }

  String overrideprePersist() {
    if (entity.prePersist == null) {
      return '';
    }
    return overrideEvent('prePersist', entity.prePersist!);
  }

  String overridepostPersist() {
    if (entity.postPersist == null) {
      return '';
    }
    return overrideEvent('postPersist', entity.postPersist!);
  }

  String overridepreUpdate() {
    if (entity.preUpdate == null) {
      return '';
    }
    return overrideEvent('preUpdate', entity.preUpdate!);
  }

  String overridepostUpdate() {
    if (entity.postUpdate == null) {
      return '';
    }
    return overrideEvent('postUpdate', entity.postUpdate!);
  }

  String overridepreRemove() {
    if (entity.preRemove == null) {
      return '';
    }
    return overrideEvent('preRemove', entity.preRemove!);
  }

  String overridepostRemove() {
    if (entity.postRemove == null) {
      return '';
    }
    return overrideEvent('postRemove', entity.postRemove!);
  }

  String overridepreRemovePermanent() {
    if (entity.preRemovePermanent == null) {
      return '';
    }
    return overrideEvent('preRemovePermanent', entity.preRemovePermanent!);
  }

  String overridepostRemovePermanent() {
    if (entity.postRemovePermanent == null) {
      return '';
    }
    return overrideEvent('postRemovePermanent', entity.postRemovePermanent!);
  }

  String overrideGetField(ClassElement clazz) {
    var defaultStmt = isTopClass
        ? "if(errorOnNonExistField){ throw 'class ${clazz.name} has now such field: \$fieldName'; }"
        : "return super.__getField(fieldName, errorOnNonExistField:errorOnNonExistField);";
    return '''
      @override
      dynamic __getField(String fieldName, {errorOnNonExistField: true}) {
        switch (fieldName) {
          ${clazz.fields.map((e) => 'case "${e.name.removePrefix()}": return _${e.name.removePrefix()};').join('\n')} 
          default: $defaultStmt
        }
      }''';
  }

  String overrideSetField(ClassElement clazz) {
    var defaultStmt = isTopClass
        ? "if(errorOnNonExistField){ throw 'class ${clazz.name} has now such field: \$fieldName'; }"
        : "super.__setField(fieldName, value, errorOnNonExistField:errorOnNonExistField );";
    return '''
      @override
      void __setField(String fieldName, dynamic value, {errorOnNonExistField: true}){
        switch (fieldName) {
          ${clazz.fields.map((e) => 'case "${e.name.removePrefix()}": ${e.name.removePrefix()} = value; break;').join('\n')} 
          default: $defaultStmt
        }
      }''';
  }

  TypeChecker tsChecker = TypeChecker.fromRuntime(DateTime);

  String _toMap(FieldElement field) {
    var isDate = field.type.toString().startsWith("DateTime");
    var toStr = isDate ? '?.toIso8601String()' : '';
    return '''"${field.name.removePrefix()}": _${field.name.removePrefix()}$toStr,''';
  }

  String overrideToMap(ClassElement clazz) {
    var superStmt = isTopClass ? "" : "...super.toMap(),";
    return '''
      @override
        Map<String, dynamic> toMap() {
          return {
            ${clazz.fields.map(_toMap).join('\n')} 
            ${superStmt}
          };
        }''';
  }
}
