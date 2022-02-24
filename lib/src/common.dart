String strModelInspector(Iterable<String> classes) {
  var metaInfoCaseStmt = classes
      .map((name) => "case '$name': return OrmMetaInfo$name();")
      .join('\n');

  var newInstanceCaseStmt =
      classes.map((name) => "case '$name': return $name();").join('\n');

  var classNameStmt =
      classes.map((name) => "if (obj is $name) return '$name';").join('\n');

  return '''
  class _ModelInspector extends ModelInspector<__Model> {


    @override
    String getEntityClassName(__Model obj) {
      $classNameStmt
      throw 'unknown entity : \$obj';
    }

    @override
    get allOrmMetaInfoClasses => _allOrmClasses;
    
    @override
    OrmMetaInfoClass? metaInfo(String entityClassName) {
      var list = _allOrmClasses
          .where((element) => element.name == entityClassName)
          .toList();
      if (list.isNotEmpty) {
        return list.first;
      }
      return null;
    }


    @override
    dynamic getFieldValue(__Model obj, String fieldName) {
      return obj.__getField(fieldName);
    }

    @override
    void setFieldValue(__Model obj, String fieldName, dynamic value) {
      obj.__setField(fieldName, value);
    }
    
    @override
    Map<String, dynamic> getDirtyFields(__Model model) {
      var map = <String, dynamic>{};
      model.__dirtyFields.forEach((name) {
        map[name] = model.__getField(name);
      });
      return map;
    }

    @override
    void loadEntity(__Model model, Map<String, dynamic> m,
        {errorOnNonExistField: false}) {
      model.loadMap(m, errorOnNonExistField: false);
      model.__isLoadedFromDb = true;
      model.__cleanDirty();
    }

    @override
    __Model newInstance(String entityClassName) {
      switch (entityClassName) {
        $newInstanceCaseStmt
        default:
          throw 'unknown class : \$entityClassName';
      }
    }
  }
  ''';
}

const strSqlExecutor = '''
  class _SqlExecutor extends SqlExecutor<__Model> {
    _SqlExecutor() : super(_ModelInspector());

    @override
    Future<List<List>> query(
        String tableName, String query, Map<String, dynamic> substitutionValues,
        [List<String> returningFields = const []]) {
      DataSource ds = use(
        scopeKeyDefaultDs); // get a DataSource from Scope , see routes.dart #post(Book)
      return ds.execute(tableName, query, substitutionValues, returningFields);
    }
  }
  ''';

const strModel = '''
  abstract class __Model extends Model {
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
    final __dirtyFields = <String>{};

    void loadMap(Map<String, dynamic> m, {errorOnNonExistField: false}) {
      m.forEach((key, value) {
        __setField(key, value, errorOnNonExistField: errorOnNonExistField);
      });
    }

    void __markDirty(String fieldName){
      __dirtyFields.add(fieldName);
    }

    void __cleanDirty() {
      __dirtyFields.clear();
    }

    String __dirtyValues() {
      return __dirtyFields.map((e) => "\${e.toLowerCase()} : \${__getField(e)}").join(", ");
    }

    void insert() {
      __prePersist();
      sqlExecutor.insert(this);
      __postPersist();
    }

    void update() {
      __preUpdate();
      sqlExecutor.update(this);
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
      sqlExecutor.delete(this);
      __postRemove();
    }

    void deletePermanent() {
      __preRemovePermanent();
      sqlExecutor.deletePermanent(this);
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

const strModelQuery = '''
  abstract class _BaseModelQuery<T extends __Model, D> extends BaseModelQuery<T, D> {
    _BaseModelQuery() : super(sqlExecutor);
  }
  ''';
