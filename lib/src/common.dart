String strModelInspector(Iterable<String> classes) {
  var newInstanceCaseStmt = classes
      .map((name) =>
          "case '$name': return $name()..__markAttached(true, topQuery as _BaseModelQuery);")
      .join('\n');

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
      model.__dbAttached = true;
      model.__dbLoaded = true;
      model.__cleanDirty();
    }

    @override
    __Model newInstance(String className,
      {bool attachDb = false, required BaseModelQuery topQuery}) {
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

    @override
    void markLoaded(__Model model) {
      model.__markLoaded(true);
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
    bool __dbLoaded = false; // if fields has been loaded from db.
    bool __dbAttached = false; // if this instance is created by Query
    _BaseModelQuery? __topQuery;

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


    void __markAttached(bool attached, _BaseModelQuery topQuery) {
      __dbAttached = attached;
      __topQuery = topQuery;
      topQuery.cache(this);
    }

    void __markLoaded(bool loaded) {
      __dbLoaded = loaded;
    }

    void __ensureLoaded() {
      if (__dbAttached && !__dbLoaded) {
        __topQuery?.ensureLoaded(this);
      }
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

const strModelCache = r'''
/// cache bound with a top query
class QueryModelCache {
  final ModelInspector modelInspector;
  Map<String, List<__Model>> cacheMap = {};

  QueryModelCache(this.modelInspector);

  void add(__Model m) {
    var className = modelInspector.getClassName(m);
    var list = cacheMap[className] ?? [];
    if (!list.contains(m)) {
      list.add(m);
    }
    cacheMap[className] = list;
  }

  Iterable<__Model> findUnloadedList(String className) {
    cacheMap[className] ??= [];
    return cacheMap[className]!.where((e) => !e.__dbLoaded);
  }
}
''';

const strBaseQuery = r'''
abstract class _BaseModelQuery<T extends __Model, D>
    extends BaseModelQuery<T, D> {
  late QueryModelCache _modelCache;

  _BaseModelQuery({BaseModelQuery? topQuery, String? propName})
      : super(_modelInspector, sqlExecutor,
            topQuery: topQuery, propName: propName) {
    this._modelCache = QueryModelCache(modelInspector);
  }

  void cache(__Model m) {
    _modelCache.add(m);
  }

  void ensureLoaded(Model m) {
    if ((m as __Model).__dbLoaded) return;
    var className = modelInspector.getClassName(m);
    var idFieldName = m.__idFieldName;
    List<Model> modelList = _modelCache.findUnloadedList(className).toList();
    List<dynamic> idList = modelList
        .map((e) => modelInspector.getFieldValue(e, idFieldName!))
        .toList(growable: false);
    var newQuery = modelInspector.newQuery(className);
    var modelListResult =
        waitFor(newQuery.findByIds(idList, existModeList: modelList));
    for (Model m in modelListResult) {
      (m as __Model).__markLoaded(true);
    }
  }
  
}
''';

const strFieldFilter = r'''
  /// support toMap(fields:'*'), toMap(fields:'name,price,author(*),editor(name,email)')
  class FieldFilter {
    final String fields;
    final String? idField;

    List<String> _fieldList = [];

    List<String> get fieldList => List.of(_fieldList);

    FieldFilter(this.fields, this.idField) {
      _fieldList = _parseFields();
    }

    bool contains(String field) {
      if (shouldIncludeIdFields()) {
        if (field == idField) {
          return true;
        }
      }
      return fieldList.any(
          (name) => name == '*' || name == field || name.startsWith('$field('));
    }

    bool shouldIncludeIdFields() {
      return fields.trim().isEmpty;
    }

    String subFilter(String field) {
      List<String> subList = fieldList
          .where((name) => name == field || name.startsWith('$field('))
          .toList();
      if (subList.isEmpty) {
        return '';
      }
      var str = subList.first;
      int i = str.indexOf('(');
      if (i != -1) {
        return str.substring(i + 1, str.length - 1);
      }
      return '';
    }

    List<String> _parseFields() {
      var result = <String>[];
      var str = fields.trim().replaceAll(' ', '');
      int j = 0;
      for (int i = 1; i < str.length; i++) {
        if (str[i] == ',') {
          result.add(str.substring(j, i));
          j = i + 1;
        } else if (str[i] == '(') {
          int k = _readTillParenthesisEnd(str, i + 1);
          if (k == -1) {
            throw '( and ) do NOT match';
          }
          i = k;
        }
      }
      if (j < str.length) {
        result.add(str.substring(j));
      }
      return result;
    }

    int _readTillParenthesisEnd(String str, int index) {
      int left = 1;
      for (; index < str.length; index++) {
        if (str[index] == ')') {
          left--;
        } else if (str[index] == '(') {
          left++;
        }
        if (left == 0) {
          return index;
        }
      }
      return -1;
    }
  }

''';
