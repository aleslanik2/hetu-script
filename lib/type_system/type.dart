import 'package:quiver/core.dart';

import '../common/lexicon.dart';
import '../implementation/object.dart';
import '../implementation/class.dart';
import '../implementation/interpreter.dart';
import 'value_type.dart';
import 'nominal_type.dart';

class HTType with HTObject {
  static const TYPE = _PrimitiveType(HTLexicon.TYPE);
  static const ANY = _PrimitiveType(HTLexicon.ANY);
  static const NULL = _PrimitiveType(HTLexicon.NULL);
  static const VOID = _PrimitiveType(HTLexicon.VOID);
  static const ENUM = _PrimitiveType(HTLexicon.ENUM);
  static const NAMESPACE = _PrimitiveType(HTLexicon.NAMESPACE);
  static final CLASS = _PrimitiveType(HTLexicon.CLASS);
  static const unknown = _PrimitiveType(HTLexicon.unknown);
  static const object = _PrimitiveType(HTLexicon.object);
  static const function = _PrimitiveType(HTLexicon.function);

  static String parseBaseType(String typeString) {
    final argsStart = typeString.indexOf(HTLexicon.typesBracketLeft);
    if (argsStart != -1) {
      final id = typeString.substring(0, argsStart);
      return id;
    } else {
      return typeString;
    }
  }

  @override
  HTType get valueType => HTType.TYPE;

  final String id;
  final List<HTType> typeArgs;
  final bool isNullable;

  bool get isPrimitive => false;

  const HTType(this.id, {this.typeArgs = const [], this.isNullable = false});

  @override
  String toString() {
    var typeString = StringBuffer();
    typeString.write(id);
    // if (typeArgs.isNotEmpty) {
    //   typeString.write(HTLexicon.angleLeft);
    //   for (var i = 0; i < typeArgs.length; ++i) {
    //     typeString.write(typeArgs[i]);
    //     if ((typeArgs.length > 1) && (i != typeArgs.length - 1)) {
    //       typeString.write('${HTLexicon.comma} ');
    //     }
    //   }
    //   typeString.write(HTLexicon.angleRight);
    // }
    if (isNullable) {
      typeString.write(HTLexicon.nullable);
    }
    return typeString.toString();
  }

  @override
  int get hashCode {
    final hashList = <int>[];
    hashList.add(id.hashCode);
    // hashList.add(isNullable.hashCode);
    // for (final typeArg in typeArgs) {
    //   hashList.add(typeArg.hashCode);
    // }
    final hash = hashObjects(hashList);
    return hash;
  }

  /// Wether object of this [HTType] can be assigned to other [HTType]
  bool isA(dynamic other) {
    if (this == HTType.unknown) {
      if (other == HTType.ANY || other == HTType.unknown) {
        return true;
      } else {
        return false;
      }
    } else if (other == HTType.ANY) {
      return true;
    } else if (other is HTType) {
      if (this == HTType.NULL) {
        // TODO: 这里是 nullable 功能的开关
        // if (other.isNullable) {
        //   return true;
        // } else {
        //   return false;
        // }
        return true;
      } else if (id != other.id) {
        return false;
      }
      // else if (typeArgs.length != other.typeArgs.length) {
      //   return false;
      // }
      else {
        // for (var i = 0; i < typeArgs.length; ++i) {
        //   if (!typeArgs[i].isA(typeArgs[i])) {
        //     return false;
        //   }
        // }
        return true;
      }
    } else {
      return false;
    }
  }

  /// initialize the declared type if it's a class name.
  /// only return the [HTClass] when its a non-external class
  HTValueType resolve(Interpreter interpreter) {
    final typeDef = interpreter.curNamespace
        .fetch(id, from: interpreter.curNamespace.fullName);
    if (typeDef is HTClass) {
      return HTNominalType(typeDef, typeArgs: typeArgs);
    } else {
      // if (typeDef is HTFunctionObjectType)
      return typeDef;
    }
  }

  /// Wether object of this [HTType] cannot be assigned to other [HTType]
  bool isNotA(dynamic other) => !isA(other);

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}

class _PrimitiveType extends HTType {
  @override
  bool get isPrimitive => true;

  const _PrimitiveType(String id) : super(id);
}
