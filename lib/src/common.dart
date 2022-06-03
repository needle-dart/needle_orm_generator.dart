String strModelInspector(Iterable<String> classes) {
  var newInstanceCaseStmt =
      classes.map((name) => "case '$name': return $name();").join('\n');

  var classNameStmt =
      classes.map((name) => "if (obj is $name) return '$name';").join('\n');

  var caseQueryStmt = classes
      .map((name) => "case '$name': return ${name}ModelQuery();")
      .join("\n");

  return '''
  class _ModelInspector extends ModelInspector<__Model> {


    @override
    String getClassName(__Model obj) {
      $classNameStmt
      throw 'unknown entity : \$obj';
    }

    @override
    get allOrmMetaClasses => _allOrmClasses;
    
    @override
    OrmMetaClass? meta(String className) {
      var list = _allOrmClasses
          .where((element) => element.name == className)
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
    void loadModel(__Model model, Map<String, dynamic> m,
        {errorOnNonExistField: false}) {
      model.loadMap(m, errorOnNonExistField: false);
      model.__isLoadedFromDb = true;
      model.__cleanDirty();
    }

    @override
    __Model newInstance(String className) {
      switch (className) {
        $newInstanceCaseStmt
        default:
          throw 'unknown class : \$className';
      }
    }

    BaseModelQuery newQuery(String name) {
      switch (name) {
        $caseQueryStmt
      }
      throw 'Unknow Query Name: \$name';
    }
  }

  final _ModelInspector _modelInspector = _ModelInspector();

  ''';
}

const strSqlExecutor = '''
  class _SqlExecutor extends SqlExecutor<__Model> {
    _SqlExecutor() : super(_ModelInspector());

    @override
    Future<List<List>> query(
        String tableName, String query, Map<String, dynamic> substitutionValues,
        [List<String> returningFields = const []]) {
      return _globalDs.execute(tableName, query, substitutionValues, returningFields);
    }
  }

  final sqlExecutor = _SqlExecutor();

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

    BaseModelQuery get __query => _modelInspector.newQuery(className);

    Future<void> insert() async {
      __prePersist();
      await __query.insert(this);
      __postPersist();
    }

    Future<void> update() async {
      __preUpdate();
      await __query.update(this);
      __postUpdate();
    }

    Future<void> save() async {
      if (__idFieldName == null) throw 'no @ID field';

      if (__getField(__idFieldName!) != null) {
        await update();
      } else {
        await insert();
      }
    }

    Future<void> delete() async {
      __preRemove();
      await __query.delete(this);
      __postRemove();
    }

    Future<void> deletePermanent() async {
      __preRemovePermanent();
      await __query.deletePermanent(this);
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
