import '../interpreter/abstract_interpreter.dart';
import '../value/entity.dart';
import '../type/type.dart';
import '../type/nominal_type.dart';
import '../type/external_type.dart';
// import '../grammar/semantic.dart';
import '../error/error.dart';
import '../value/function/function.dart';
import '../value/class/class.dart';
import 'external_class.dart';
import '../value/external_enum/external_enum.dart';

/// Class for external object.
class HTExternalInstance<T> with HTEntity, InterpreterRef {
  @override
  late final HTType valueType;

  /// the external object.
  final T externalObject;
  final String typeString;
  late final HTExternalClass? externalClass;

  HTClass? klass;

  HTExternalEnum? enumClass;

  /// Create a external class object.
  HTExternalInstance(
      this.externalObject, HTAbstractInterpreter interpreter, this.typeString) {
    this.interpreter = interpreter;
    final id = HTType.parseBaseType(typeString);
    if (interpreter.containsExternalClass(id)) {
      externalClass = interpreter.fetchExternalClass(id);
    } else {
      externalClass = null;
    }

    final def = interpreter.namespace.memberGet(id, error: false);
    if (def is HTClass) {
      klass = def;
    } else if (def is HTExternalEnum) {
      enumClass = def;
    }
    if (klass != null) {
      valueType = HTNominalType(klass!);
    } else {
      valueType = HTExternalType(typeString);
    }
  }

  @override
  dynamic memberGet(String varName) {
    if (externalClass != null) {
      final member = externalClass!.instanceMemberGet(externalObject, varName);
      if (member is Function && klass != null) {
        // final getter = '${SemanticNames.getter}$varName';
        // if (klass!.namespace.declarations.containsKey(varName)) {
        HTFunction func =
            klass!.memberGet(varName, recursive: false, internal: true);
        func.externalFunc = member;
        return func;
        // } else if (klass!.namespace.declarations.containsKey(getter)) {
        //   HTFunction func = klass!.namespace.declarations[getter]!.value;
        //   func.externalFunc = member;
        //   return func;
        // }
      } else {
        return member;
      }
    } else {
      throw HTError.undefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, varName, varValue);
    } else {
      throw HTError.unknownExternalTypeName(typeString);
    }
  }
}
