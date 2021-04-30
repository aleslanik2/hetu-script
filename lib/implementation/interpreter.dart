import 'package:hetu_script/implementation/parser.dart';
import 'package:pub_semver/pub_semver.dart';

import '../plugin/moduleHandler.dart';
import '../plugin/errorHandler.dart';
import '../binding/external_class.dart';
import '../binding/external_function.dart';
import '../binding/external_instance.dart';
import '../core/core_class.dart';
import '../core/core_function.dart';
import '../common/errors.dart';

import 'namespace.dart';
import 'type.dart';
import 'hetu_lib.dart';
import 'function.dart';
import 'object.dart';
import 'lexicon.dart';

/// Mixin for classes want to use a shared interpreter referrence.
mixin InterpreterRef {
  late final Interpreter interpreter;
}

class InterpreterConfig {
  final bool compileWithLineInfo;
  final bool reportHetuStackTrace;
  final bool reportDartStackTrace;

  InterpreterConfig(this.compileWithLineInfo, this.reportHetuStackTrace,
      this.reportDartStackTrace);
}

/// Shared interface for a ast or bytecode interpreter of Hetu.
abstract class Interpreter {
  final version = Version(0, 1, 0);

  int get curLine;
  int get curColumn;
  String? get curModuleFullName;

  String? get curSymbol;
  String? get curObjectSymbol;

  HTNamespace get curNamespace;

  late HTErrorHandler errorHandler;
  late HTModuleHandler moduleHandler;

  /// 全局命名空间
  late HTNamespace global;

  Interpreter({HTErrorHandler? errorHandler, HTModuleHandler? moduleHandler}) {
    this.errorHandler = errorHandler ?? DefaultErrorHandler();
    this.moduleHandler = moduleHandler ?? DefaultModuleHandler();
  }

  Future<void> init(
      {bool coreModule = true,
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) async {
    // load classes and functions in core library.
    if (coreModule) {
      for (final file in coreModules.keys) {
        await eval(coreModules[file]!, moduleFullName: file);
      }
      for (var key in coreFunctions.keys) {
        bindExternalFunction(key, coreFunctions[key]!);
      }
      bindExternalClass(HTNumberClass());
      bindExternalClass(HTIntegerClass());
      bindExternalClass(HTFloatClass());
      bindExternalClass(HTBooleanClass());
      bindExternalClass(HTStringClass());
      bindExternalClass(HTListClass());
      bindExternalClass(HTMapClass());
      bindExternalClass(HTMathClass());
      bindExternalClass(HTSystemClass());
      bindExternalClass(HTConsoleClass());
    }

    for (var key in externalFunctions.keys) {
      bindExternalFunction(key, externalFunctions[key]!);
    }

    for (var key in externalFunctionTypedef.keys) {
      bindExternalFunctionType(key, externalFunctionTypedef[key]!);
    }

    for (var value in externalClasses) {
      bindExternalClass(value);
    }
  }

  Future<dynamic> eval(String content,
      {String? moduleFullName,
      HTNamespace? namespace,
      ParserConfig config = const ParserConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  /// 解析文件
  Future<dynamic> import(String key,
      {String? curModuleFullName,
      String? moduleName,
      ParserConfig config = const ParserConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []});

  /// 调用一个全局函数或者类、对象上的函数
  // TODO: 调用构造函数
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  void handleError(Object error, [StackTrace? stack]);

  HTObject encapsulate(dynamic object) {
    if (object is HTObject) {
      return object;
    } else if ((object == null) || (object is NullThrownError)) {
      return HTObject.NULL;
    }

    String? typeString;

    if (object is bool) {
      typeString = HTLexicon.boolean;
    } else if (object is int) {
      typeString = HTLexicon.integer;
    } else if (object is double) {
      typeString = HTLexicon.float;
    } else if (object is String) {
      typeString = HTLexicon.string;
    } else if (object is List) {
      typeString = HTLexicon.list;
      // var valueType = HTType.ANY;
      // if (object.isNotEmpty) {
      //   valueType = encapsulate(object.first).objectType;
      //   for (final item in object) {
      //     final value = encapsulate(item).objectType;
      //     if (value.isNotA(valueType)) {
      //       valueType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // return HTList(object, this, valueType: valueType);
    } else if (object is Map) {
      typeString = HTLexicon.map;
      // var keyType = HTType.ANY;
      // var valueType = HTType.ANY;
      // if (object.keys.isNotEmpty) {
      //   keyType = encapsulate(object.keys.first).objectType;
      //   for (final item in object.keys) {
      //     final value = encapsulate(item).objectType;
      //     if (value.isNotA(keyType)) {
      //       keyType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // if (object.values.isNotEmpty) {
      //   valueType = encapsulate(object.values.first).objectType;
      //   for (final item in object.values) {
      //     final value = encapsulate(item).objectType;
      //     if (value.isNotA(valueType)) {
      //       valueType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // return HTMap(object, this, keyType: keyType, valueType: valueType);
    } else {
      var reflected = false;
      for (final reflect in _externTypeReflection) {
        final result = reflect(object);
        if (result.success) {
          reflected = true;
          typeString = result.typeString;
          break;
        }
      }
      if (!reflected) {
        typeString = object.runtimeType.toString();
        typeString = HTType.parseBaseType(typeString);
      }
    }

    return HTExternalInstance(object, this, typeString);
  }

  final _externClasses = <String, HTExternalClass>{};
  final _externFuncs = <String, Function>{};
  final _externFuncTypeUnwrappers = <String, HTExternalFunctionTypedef>{};
  final _externTypeReflection = <HTExternalTypeReflection>[];

  bool containsExternalClass(String id) => _externClasses.containsKey(id);

  /// 注册外部类，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalClass(HTExternalClass externalClass) {
    if (_externClasses.containsKey(externalClass.objectType)) {
      throw HTError.definedRuntime(externalClass.objectType.toString());
    }
    _externClasses[externalClass.id] = externalClass;
  }

  HTExternalClass fetchExternalClass(String id) {
    if (!_externClasses.containsKey(id)) {
      throw HTError.undefinedExtern(id);
    }
    return _externClasses[id]!;
  }

  void bindExternalFunction(String id, Function function) {
    if (_externFuncs.containsKey(id)) {
      throw HTError.definedRuntime(id);
    }
    _externFuncs[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFuncs.containsKey(id)) {
      throw HTError.undefinedExtern(id);
    }
    return _externFuncs[id]!;
  }

  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function) {
    if (_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTError.definedRuntime(id);
    }
    _externFuncTypeUnwrappers[id] = function;
  }

  Function unwrapExternalFunctionType(String id, HTFunction function) {
    if (!_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTError.undefinedExtern(id);
    }
    final unwrapFunc = _externFuncTypeUnwrappers[id]!;
    return unwrapFunc(function);
  }

  /// Bind a external class name to a abstract class name for interpreter get dart class name by reflection
  void bindExternalReflection(HTExternalTypeReflection reflection) {
    _externTypeReflection.add(reflection);
  }
}