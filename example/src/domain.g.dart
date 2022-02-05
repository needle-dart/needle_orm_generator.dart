// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

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
    return __dirtyMap.keys.map((e) => "$e:${__getField(e)}").join(",");
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

abstract class BaseModel extends __Model {
  int? _id;
  int? get id => _id;
  set id(int? v) {
    _id = v;
    __dirtyMap['_id'] = true;
  }

  int? _version;
  int? get version => _version;
  set version(int? v) {
    _version = v;
    __dirtyMap['_version'] = true;
  }

  bool? _deleted;
  bool? get deleted => _deleted;
  set deleted(bool? v) {
    _deleted = v;
    __dirtyMap['_deleted'] = true;
  }

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  set createdAt(DateTime? v) {
    _createdAt = v;
    __dirtyMap['_createdAt'] = true;
  }

  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  set updatedAt(DateTime? v) {
    _updatedAt = v;
    __dirtyMap['_updatedAt'] = true;
  }

  String? _createdBy;
  String? get createdBy => _createdBy;
  set createdBy(String? v) {
    _createdBy = v;
    __dirtyMap['_createdBy'] = true;
  }

  String? _lastUpdatedBy;
  String? get lastUpdatedBy => _lastUpdatedBy;
  set lastUpdatedBy(String? v) {
    _lastUpdatedBy = v;
    __dirtyMap['_lastUpdatedBy'] = true;
  }

  String? _remark;
  String? get remark => _remark;
  set remark(String? v) {
    _remark = v;
    __dirtyMap['_remark'] = true;
  }

  BaseModel();

  dynamic __getField(String fieldName) {
    switch (fieldName) {
      case "_id":
        return _id;
      case "_version":
        return _version;
      case "_deleted":
        return _deleted;
      case "_createdAt":
        return _createdAt;
      case "_updatedAt":
        return _updatedAt;
      case "_createdBy":
        return _createdBy;
      case "_lastUpdatedBy":
        return _lastUpdatedBy;
      case "_remark":
        return _remark;
      default:
        throw 'class _BaseModel has now such field: $fieldName';
    }
  }

  String? __getIdFieldName() {
    return "_id";
  }
}

class Book extends BaseModel {
  String? _title;
  String? get title => _title;
  set title(String? v) {
    _title = v;
    __dirtyMap['_title'] = true;
  }

  User? _author;
  User? get author => _author;
  set author(User? v) {
    _author = v;
    __dirtyMap['_author'] = true;
  }

  Book();

  dynamic __getField(String fieldName) {
    switch (fieldName) {
      case "_title":
        return _title;
      case "_author":
        return _author;
      default:
        return super.__getField(fieldName);
    }
  }

  String? __getIdFieldName() {
    return "_id";
  }
}

class User extends BaseModel {
  String? _name;
  String? get name => _name;
  set name(String? v) {
    _name = v;
    __dirtyMap['_name'] = true;
  }

  String? _loginName;
  String? get loginName => _loginName;
  set loginName(String? v) {
    _loginName = v;
    __dirtyMap['_loginName'] = true;
  }

  String? _address;
  String? get address => _address;
  set address(String? v) {
    _address = v;
    __dirtyMap['_address'] = true;
  }

  int? _age;
  int? get age => _age;
  set age(int? v) {
    _age = v;
    __dirtyMap['_age'] = true;
  }

  User();

  dynamic __getField(String fieldName) {
    switch (fieldName) {
      case "_name":
        return _name;
      case "_loginName":
        return _loginName;
      case "_address":
        return _address;
      case "_age":
        return _age;
      default:
        return super.__getField(fieldName);
    }
  }

  String? __getIdFieldName() {
    return "_id";
  }
}

class Job extends BaseModel {
  String? _name;
  String? get name => _name;
  set name(String? v) {
    _name = v;
    __dirtyMap['_name'] = true;
  }

  Job();

  dynamic __getField(String fieldName) {
    switch (fieldName) {
      case "_name":
        return _name;
      default:
        return super.__getField(fieldName);
    }
  }

  String? __getIdFieldName() {
    return "_id";
  }
}
