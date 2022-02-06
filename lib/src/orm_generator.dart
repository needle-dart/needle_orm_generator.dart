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
      beforeInsert: this.peek("beforeInsert")?.stringValue,
      beforeUpdate: this.peek("beforeUpdate")?.stringValue,
      beforeDelete: this.peek("beforeDelete")?.stringValue,
      beforeDeletePermanent: this.peek("beforeDeletePermanent")?.stringValue,
      afterInsert: this.peek("afterInsert")?.stringValue,
      afterUpdate: this.peek("afterUpdate")?.stringValue,
      afterDelete: this.peek("afterDelete")?.stringValue,
      afterDeletePermanent: this.peek("afterDeletePermanent")?.stringValue,
      afterLoad: this.peek("afterLoad")?.stringValue,
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

      ${overrideBeforeInsert()}
      ${overrideBeforeUpdate()}
      ${overrideBeforeDelete()}
      ${overrideBeforeDeletePermanent()}
      ${overrideAfterInsert()}
      ${overrideAfterUpdate()}
      ${overrideAfterDelete()}
      ${overrideAfterDeletePermanent()}
      ${overrideAfterLoad()}

    }''';
  }

  String overrideEvent(String eventType, String eventHandler) {
    return '''
      @override void __${eventType}() {
        ${eventHandler}();
      }
      ''';
  }

  String overrideAfterLoad() {
    if (entity.afterLoad == null) {
      return '';
    }
    return overrideEvent('afterLoad', entity.afterLoad!);
  }

  String overrideBeforeInsert() {
    if (entity.beforeInsert == null) {
      return '';
    }
    return overrideEvent('beforeInsert', entity.beforeInsert!);
  }

  String overrideAfterInsert() {
    if (entity.afterInsert == null) {
      return '';
    }
    return overrideEvent('afterInsert', entity.afterInsert!);
  }

  String overrideBeforeUpdate() {
    if (entity.beforeUpdate == null) {
      return '';
    }
    return overrideEvent('beforeUpdate', entity.beforeUpdate!);
  }

  String overrideAfterUpdate() {
    if (entity.afterUpdate == null) {
      return '';
    }
    return overrideEvent('afterUpdate', entity.afterUpdate!);
  }

  String overrideBeforeDelete() {
    if (entity.beforeDelete == null) {
      return '';
    }
    return overrideEvent('beforeDelete', entity.beforeDelete!);
  }

  String overrideAfterDelete() {
    if (entity.afterDelete == null) {
      return '';
    }
    return overrideEvent('afterDelete', entity.afterDelete!);
  }

  String overrideBeforeDeletePermanent() {
    if (entity.beforeDeletePermanent == null) {
      return '';
    }
    return overrideEvent(
        'beforeDeletePermanent', entity.beforeDeletePermanent!);
  }

  String overrideAfterDeletePermanent() {
    if (entity.afterDeletePermanent == null) {
      return '';
    }
    return overrideEvent('afterDeletePermanent', entity.afterDeletePermanent!);
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
          ${clazz.fields.map((e) => 'case "${e.name.removePrefix()}": _${e.name.removePrefix()} = value; break;').join('\n')} 
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
        __beforeInsert();
        print('insert into \$__tableName { \${__dirtyValues()}  }' );
        __afterInsert();
      }

      void update() {
        __beforeUpdate();
        print('update \$__tableName { \${__dirtyValues()} }' );
        __afterUpdate();
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
        __beforeDelete();
        print('delete ...');
        __afterDelete();
      }

      void deletePermanent() {
        __beforeDeletePermanent();
        print('deletePermanent ...');
        __afterDeletePermanent();
      }

      void __beforeInsert() {}
      void __beforeUpdate() {}
      void __beforeDelete() {}
      void __beforeDeletePermanent() {}
      void __afterInsert() {}
      void __afterUpdate() {}
      void __afterDelete() {}
      void __afterDeletePermanent() {}
      void __afterLoad() {}
    }
    ''';
}
