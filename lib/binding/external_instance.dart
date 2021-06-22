import '../interpreter/abstract_interpreter.dart';
import '../element/object.dart';
import '../type/type.dart';
import '../type/nominal_type.dart';
import '../grammar/semantic.dart';
import '../error/error.dart';
import '../element/function/typed_function_declaration.dart';
import '../element/class/class.dart';
import 'external_class.dart';

/// Class for external object.
class HTExternalInstance<T> with HTObject, InterpreterRef {
  @override
  late final HTType valueType;

  /// the external object.
  final T externalObject;
  final String typeString;
  late final HTExternalClass? externalClass;

  HTClass? klass;

  /// Create a external class object.
  HTExternalInstance(
      this.externalObject, AbstractInterpreter interpreter, this.typeString) {
    this.interpreter = interpreter;
    final id = HTType.parseBaseType(typeString);
    if (interpreter.containsExternalClass(id)) {
      externalClass = interpreter.fetchExternalClass(id);
    } else {
      externalClass = null;
    }

    try {
      klass = interpreter.curNamespace.memberGet(id);
    } finally {
      if (klass != null) {
        valueType = HTNominalType(klass!);
      } else {
        valueType = HTType(typeString, interpreter.curModuleFullName,
            interpreter.curLibraryName);
      }
    }
  }

  @override
  dynamic memberGet(String field,
      {String from = SemanticNames.global, bool error = true}) {
    switch (field) {
      case 'valueType':
        return valueType;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toString();
      default:
        if (externalClass != null) {
          final member =
              externalClass!.instanceMemberGet(externalObject, field);
          if (member is Function) {
            final getter = '${SemanticNames.getter}$field';
            if (klass!.instanceMembers.containsKey(field)) {
              HTTypedFunctionDeclaration func =
                  klass!.instanceMembers[field]!.value;
              func.externalFunc = member;
              return func;
            } else if (klass!.instanceMembers.containsKey(getter)) {
              HTTypedFunctionDeclaration func =
                  klass!.instanceMembers[getter]!.value;
              func.externalFunc = member;
              return func;
            }
          }
          return member;
        } else {
          if (error) {
            throw HTError.undefined(field);
          }
        }
    }
  }

  @override
  void memberSet(String field, dynamic varValue,
      {String from = SemanticNames.global, bool error = true}) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, field, varValue);
    } else {
      throw HTError.unknownTypeName(typeString);
    }
  }
}
