/// Operation code used by compiler.
abstract class HTOpCode {
  static const endOfCode = -1;
  static const local = 1;
  static const register = 2;
  static const copy = 3;
  static const skip = 4;
  static const anchor = 5;
  static const goto = 6;
  static const moveReg = 7;
  static const leftValue = 8;
  static const loopPoint = 10;
  static const breakLoop = 11;
  static const continueLoop = 12;
  static const assertion = 13;
  static const endOfStmt = 20;
  static const endOfBlock = 21;
  static const endOfExec = 22;
  static const endOfFunc = 23;
  static const endOfFile = 24;
  static const ifStmt = 26;
  static const whileStmt = 27;
  static const doStmt = 28;
  static const whenStmt = 29;
  static const block = 30;
  static const library = 31;
  static const file = 32;
  static const constTable = 33;
  static const importExportDecl = 40;
  static const libraryDecl = 41;
  static const namespaceDecl = 42;
  static const typeAliasDecl = 43;
  static const funcDecl = 44;
  static const classDecl = 45;
  static const externalEnumDecl = 46;
  static const structDecl = 47;
  static const varDecl = 48;
  static const constDecl = 49;
  static const assign = 50;
  static const memberSet = 51;
  static const subSet = 52;
  static const logicalOr = 53;
  static const logicalAnd = 54;
  static const equal = 55;
  static const notEqual = 56;
  static const lesser = 57;
  static const greater = 58;
  static const lesserOrEqual = 59;
  static const greaterOrEqual = 60;
  static const typeAs = 61;
  static const typeIs = 62;
  static const typeIsNot = 63;
  static const ifNull = 64;
  static const add = 65;
  static const subtract = 66;
  static const multiply = 67;
  static const devide = 68;
  static const modulo = 69;
  static const negative = 70;
  static const logicalNot = 71;
  static const typeOf = 72;
  static const memberGet = 73;
  static const subGet = 74;
  static const call = 75;
  static const meta = 200;
  static const lineInfo = 205;
}

/// Following a local OpCode, tells the value type, used by compiler.
abstract class HTValueTypeCode {
  static const nullValue = 0;
  static const boolean = 1;
  static const constInt = 2;
  static const constFloat = 3;
  static const constString = 4;
  static const string = 5;
  static const stringInterpolation = 6;
  static const identifier = 7;
  static const subValue = 8;
  static const group = 9;
  static const list = 10;
  static const struct = 11;
  static const function = 12;
  static const type = 13;
}

abstract class StructObjFieldType {
  static const normal = 0;
  static const spread = 1;
  static const objectIdentifier = 2;
}
