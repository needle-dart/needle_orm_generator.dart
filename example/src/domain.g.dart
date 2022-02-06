// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

abstract class __Model {
  // abstract begin

  String get __tableName;
  String? get __idFieldName;

  dynamic __getField(String fieldName, {errorOnNonExistField: true});
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
    return __dirtyMap.keys
        .map((e) => "${e.toLowerCase()} : ${__getField(e)}")
        .join(", ");
  }

  void insert() {
    __prePersist();
    print('insert into $__tableName { ${__dirtyValues()}  }');
    __postPersist();
  }

  void update() {
    __preUpdate();
    print('update $__tableName { ${__dirtyValues()} }');
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

abstract class BaseModel extends __Model {
  int? _id;
  int? get id => _id;
  set id(int? v) {
    _id = v;
    __dirtyMap['id'] = true;
  }

  int? _version;
  int? get version => _version;
  set version(int? v) {
    _version = v;
    __dirtyMap['version'] = true;
  }

  bool? _deleted;
  bool? get deleted => _deleted;
  set deleted(bool? v) {
    _deleted = v;
    __dirtyMap['deleted'] = true;
  }

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  set createdAt(DateTime? v) {
    _createdAt = v;
    __dirtyMap['createdAt'] = true;
  }

  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  set updatedAt(DateTime? v) {
    _updatedAt = v;
    __dirtyMap['updatedAt'] = true;
  }

  String? _createdBy;
  String? get createdBy => _createdBy;
  set createdBy(String? v) {
    _createdBy = v;
    __dirtyMap['createdBy'] = true;
  }

  String? _lastUpdatedBy;
  String? get lastUpdatedBy => _lastUpdatedBy;
  set lastUpdatedBy(String? v) {
    _lastUpdatedBy = v;
    __dirtyMap['lastUpdatedBy'] = true;
  }

  String? _remark;
  String? get remark => _remark;
  set remark(String? v) {
    _remark = v;
    __dirtyMap['remark'] = true;
  }

  BaseModel();

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "id":
        return _id;
      case "version":
        return _version;
      case "deleted":
        return _deleted;
      case "createdAt":
        return _createdAt;
      case "updatedAt":
        return _updatedAt;
      case "createdBy":
        return _createdBy;
      case "lastUpdatedBy":
        return _lastUpdatedBy;
      case "remark":
        return _remark;
      default:
        if (errorOnNonExistField)
          throw 'class _BaseModel has now such field: $fieldName';
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "id":
        _id = value;
        break;
      case "version":
        _version = value;
        break;
      case "deleted":
        _deleted = value;
        break;
      case "createdAt":
        _createdAt = value;
        break;
      case "updatedAt":
        _updatedAt = value;
        break;
      case "createdBy":
        _createdBy = value;
        break;
      case "lastUpdatedBy":
        _lastUpdatedBy = value;
        break;
      case "remark":
        _remark = value;
        break;
      default:
        if (errorOnNonExistField)
          throw 'class _BaseModel has now such field: $fieldName';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "id": _id,
      "version": _version,
      "deleted": _deleted,
      "createdAt": _createdAt,
      "updatedAt": _updatedAt,
      "createdBy": _createdBy,
      "lastUpdatedBy": _lastUpdatedBy,
      "remark": _remark,
    };
  }

  @override
  String get __tableName {
    return "basemodel";
  }

  @override
  String? get __idFieldName {
    return "id";
  }
}

class Book extends BaseModel {
  String? _title;
  String? get title => _title;
  set title(String? v) {
    _title = v;
    __dirtyMap['title'] = true;
  }

  User? _author;
  User? get author => _author;
  set author(User? v) {
    _author = v;
    __dirtyMap['author'] = true;
  }

  Book();

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "title":
        return _title;
      case "author":
        return _author;
      default:
        return super
            .__getField(fieldName, errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "title":
        _title = value;
        break;
      case "author":
        _author = value;
        break;
      default:
        super.__setField(fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "title": _title,
      "author": _author,
      ...super.toMap(),
    };
  }

  @override
  String get __tableName {
    return "book";
  }

  @override
  String? get __idFieldName {
    return "id";
  }
}

class User extends BaseModel {
  String? _name;
  String? get name => _name;
  set name(String? v) {
    _name = v;
    __dirtyMap['name'] = true;
  }

  String? _loginName;
  String? get loginName => _loginName;
  set loginName(String? v) {
    _loginName = v;
    __dirtyMap['loginName'] = true;
  }

  String? _address;
  String? get address => _address;
  set address(String? v) {
    _address = v;
    __dirtyMap['address'] = true;
  }

  int? _age;
  int? get age => _age;
  set age(int? v) {
    _age = v;
    __dirtyMap['age'] = true;
  }

  User();

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "name":
        return _name;
      case "loginName":
        return _loginName;
      case "address":
        return _address;
      case "age":
        return _age;
      default:
        return super
            .__getField(fieldName, errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "name":
        _name = value;
        break;
      case "loginName":
        _loginName = value;
        break;
      case "address":
        _address = value;
        break;
      case "age":
        _age = value;
        break;
      default:
        super.__setField(fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "name": _name,
      "loginName": _loginName,
      "address": _address,
      "age": _age,
      ...super.toMap(),
    };
  }

  @override
  String get __tableName {
    return "user";
  }

  @override
  String? get __idFieldName {
    return "id";
  }

  @override
  void __prePersist() {
    beforeInsert();
  }

  @override
  void __postPersist() {
    afterInsert();
  }
}

class Job extends BaseModel {
  String? _name;
  String? get name => _name;
  set name(String? v) {
    _name = v;
    __dirtyMap['name'] = true;
  }

  Job();

  @override
  dynamic __getField(String fieldName, {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "name":
        return _name;
      default:
        return super
            .__getField(fieldName, errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  void __setField(String fieldName, dynamic value,
      {errorOnNonExistField: true}) {
    switch (fieldName) {
      case "name":
        _name = value;
        break;
      default:
        super.__setField(fieldName, value,
            errorOnNonExistField: errorOnNonExistField);
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "name": _name,
      ...super.toMap(),
    };
  }

  @override
  String get __tableName {
    return "job";
  }

  @override
  String? get __idFieldName {
    return "id";
  }
}
