import '../../interpreter/interpreter.dart';
import '../../type/type.dart';
import '../variable/variable.dart';
import 'abstract_parameter.dart';

// TODO: parameter's initializer must be a const expression.

/// An implementation of [HTVariable] for function parameter declaration.
class HTParameter extends HTVariable implements AbstractParameter {
  @override
  final bool isOptional;

  @override
  final bool isNamed;

  @override
  final bool isVariadic;

  /// Create a standard [HTParameter].
  HTParameter(String id, Hetu interpreter,
      {HTType? declType,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, interpreter,
            declType: declType,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);

  @override
  String toString() {
    final typeString = StringBuffer();
    if (declType != null) {
      typeString.write('$id: ');
      typeString.write(declType.toString());
    }
    return typeString.toString();
  }

  @override
  HTParameter clone() {
    return HTParameter(id, interpreter,
        definitionIp: definitionIp,
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }
}