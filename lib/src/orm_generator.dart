import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:needle_orm/needle_orm.dart';
import 'package:source_gen/source_gen.dart';

extension StringUtil on String {
  String removePrefix([String prefix = '_']) {
    if (this.startsWith(prefix)) {
      return this.substring(prefix.length);
    }
    return this;
  }
}

extension EntityInspector on ConstantReader {
  Entity getEntityAnnotation() {
    return Entity(
      prePersist: this.peek("prePersist")?.stringValue,
      preUpdate: this.peek("preUpdate")?.stringValue,
      preRemove: this.peek("preRemove")?.stringValue,
      preRemovePermanent: this.peek("preRemovePermanent")?.stringValue,
      postPersist: this.peek("postPersist")?.stringValue,
      postUpdate: this.peek("postUpdate")?.stringValue,
      postRemove: this.peek("postRemove")?.stringValue,
      postRemovePermanent: this.peek("postRemovePermanent")?.stringValue,
      postLoad: this.peek("postLoad")?.stringValue,
    );
  }
}

class OrmGenerator extends GeneratorForAnnotation<Entity> {
  bool commonAdded = false;

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw 'The top @OrmAnnotation() annotation can only be applied to classes.';
    }
    if (!commonAdded) {
      commonAdded = true;
      return ClassInspector(element, true, annotation).generate();
    }
    return ClassInspector(element, false, annotation).generate();
  }
}

class FieldInspector {
  final FieldElement fieldElement;
  String name;

  FieldInspector(this.fieldElement) : name = fieldElement.name.removePrefix();

  String generate() {
    var type = fieldElement.type.toString().removePrefix();

    return '''
  $type _$name ;
  $type get $name => _$name;
  set $name($type v) {
    _$name = v;
    __dirtyMap['$name'] = true;
  }
''';
  }
}

class ClassInspector {
  final ClassElement classElement;
  final bool first;
  String name;

  late String tableName;
  ClassElement? superClassElement;
  String? superName;
  late Entity entity;

  bool topClass = true;
  List<FieldElement> fields = [];

  ClassInspector(this.classElement, this.first, ConstantReader annotation)
      : name = classElement.name.removePrefix() {
    if (classElement.supertype != null &&
        classElement.supertype!.element.name != 'Object') {
      superClassElement = classElement.supertype!.element;
      superName = superClassElement!.name.removePrefix();
      topClass = false;
    }
    this.entity = annotation.getEntityAnnotation();

    tableName = name.toLowerCase();
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
    var defaultStmt = topClass
        ? "if(errorOnNonExistField) throw 'class ${clazz.name} has now such field: \$fieldName'"
        : "return super.__getField(fieldName, errorOnNonExistField:errorOnNonExistField)";
    return '''
      @override
      dynamic __getField(String fieldName, {errorOnNonExistField: true}) {
        switch (fieldName) {
          ${clazz.fields.map((e) => 'case "${e.name.removePrefix()}": return _${e.name.removePrefix()};').join('\n')} 
          default: $defaultStmt ;
        }
      }''';
  }

  String overrideSetField(ClassElement clazz) {
    var defaultStmt = topClass
        ? "if(errorOnNonExistField) throw 'class ${clazz.name} has now such field: \$fieldName'"
        : "super.__setField(fieldName, value, errorOnNonExistField:errorOnNonExistField )";
    return '''
      @override
      void __setField(String fieldName, dynamic value, {errorOnNonExistField: true}){
        switch (fieldName) {
          ${clazz.fields.map((e) => 'case "${e.name.removePrefix()}": ${e.name.removePrefix()} = value; break;').join('\n')} 
          default: $defaultStmt ;
        }
      }''';
  }

  String overrideToMap(ClassElement clazz) {
    var superStmt = topClass ? "" : "...super.toMap(),";
    return '''
      @override
        Map<String, dynamic> toMap() {
          return {
            ${clazz.fields.map((e) => '"${e.name.removePrefix()}": _${e.name.removePrefix()},').join('\n')} 
            ${superStmt}
          };
        }''';
  }

  static const common = '''
    abstract class __Model {
      // abstract begin

      String get __tableName;
      String? get __idFieldName;

      dynamic __getField(String fieldName,
        {errorOnNonExistField: true});
      void __setField(String fieldName, dynamic value,
        {errorOnNonExistField: true});

      Map<String, dynamic> toMap();

      // abstract end

      // mark whether this instance is loaded from db.
      bool __isLoadedFromDb = false;

      // mark all modified fields after loaded
      final __dirtyMap = <String, bool>{};

      void loadMap(Map<String, dynamic> m, {errorOnNonExistField: false}) {
        m.forEach((key, value) {
          __setField(key, value, errorOnNonExistField: errorOnNonExistField);
        });
      }

      void __cleanDirty() {
        __dirtyMap.clear();
      }

      String __dirtyValues() {
        return __dirtyMap.keys.map((e) => "\${e.toLowerCase()} : \${__getField(e)}").join(", ");
      }

      void insert() {
        __prePersist();
        print('insert into \$__tableName { \${__dirtyValues()}  }' );
        __postPersist();
      }

      void update() {
        __preUpdate();
        print('update \$__tableName { \${__dirtyValues()} }' );
        __postUpdate();
      }

      void save() {
        if (__idFieldName == null) throw 'no @ID field';

        if (__getField(__idFieldName!) != null) {
          update();
        } else {
          insert();
        }
      }

      void delete() {
        __preRemove();
        print('delete ...');
        __postRemove();
      }

      void deletePermanent() {
        __preRemovePermanent();
        print('deletePermanent ...');
        __postRemovePermanent();
      }

      void __prePersist() {}
      void __preUpdate() {}
      void __preRemove() {}
      void __preRemovePermanent() {}
      void __postPersist() {}
      void __postUpdate() {}
      void __postRemove() {}
      void __postRemovePermanent() {}
      void __postLoad() {}
    }
    ''';
}
