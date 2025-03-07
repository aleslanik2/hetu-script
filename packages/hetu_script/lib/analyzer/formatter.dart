import '../ast/ast.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../parser/parse_result_compilation.dart';
import '../parser/parse_result.dart';
import '../lexer/lexer.dart';
import '../parser/parser.dart';
import '../shared/stringify.dart';

class FormatterConfig {
  final int pageWidth;
  final bool formatQuotationMark;
  final bool singleQuotationMark;
  final bool removeTrailingComma;

  const FormatterConfig(
      {this.pageWidth = 80,
      this.formatQuotationMark = true,
      this.singleQuotationMark = true,
      this.removeTrailingComma = true});
}

/// Class for printing out formatted string content of a ast root
class HTFormatter implements AbstractAstVisitor<String> {
  var _curIndentCount = 0;

  AstNode? _lastStmt;

  FormatterConfig config;

  HTFormatter({this.config = const FormatterConfig()});

  String get curIndent {
    final output = StringBuffer();
    var i = _curIndentCount;
    while (i > 0) {
      output.write(HTLexicon.indentSpaces);
      --i;
    }
    return output.toString();
  }

  String format(List<AstNode> nodes, {FormatterConfig? config}) {
    final savedConfig = this.config;
    if (config != null) {
      this.config = config;
    }
    final output = StringBuffer();
    for (var i = 0; i < nodes.length; ++i) {
      final stmt = nodes[i];
      final stmtString = formatAst(stmt);
      if (stmtString.isNotEmpty) {
        if (_lastStmt is ImportExportDecl && stmt is! ImportExportDecl) {
          output.writeln('');
        }
        output.writeln(stmtString);
        if ((i < nodes.length - 1) &&
            (stmt is FuncDecl || stmt is ClassDecl || stmt is EnumDecl)) {
          output.writeln('');
        }
      }
      _lastStmt = stmt;
    }
    final result = output.toString();
    this.config = savedConfig;
    return result;
  }

  String formatString(String content, {FormatterConfig? config}) {
    final tokens = HTLexer().lex(content);
    final nodes = HTParser().parseToken(tokens);
    final result = format(nodes, config: config);
    return result;
  }

  void formatSource(HTSourceParseResult result, {FormatterConfig? config}) {
    result.source.content = format(result.nodes, config: config);
  }

  void formatModule(HTModuleParseResult module, {FormatterConfig? config}) {
    for (final result in module.results.values) {
      result.source.content = format(result.nodes, config: config);
    }
  }

  String formatAst(AstNode ast) => ast.accept(this);

  @override
  String visitEmptyExpr(EmptyExpr expr) {
    return '';
  }

  @override
  String visitNullExpr(NullExpr expr) {
    return HTLexicon.kNull;
  }

  @override
  String visitBooleanExpr(BooleanExpr expr) {
    return expr.value ? HTLexicon.kTrue : HTLexicon.kFalse;
  }

  @override
  String visitIntLiteralExpr(IntLiteralExpr expr) {
    return expr.value.toString();
  }

  @override
  String visitFloatLiteralExpr(FloatLiteralExpr expr) {
    return expr.value.toString();
  }

  @override
  String visitStringLiteralExpr(StringLiteralExpr expr) {
    return stringify(expr.value);
  }

  @override
  String visitStringInterpolationExpr(StringInterpolationExpr expr) {
    final interpolation = <String>[];
    for (final node in expr.interpolation) {
      final nodeString = formatAst(node);
      interpolation.add(nodeString);
    }
    var output = expr.value;
    for (var i = 0; i < interpolation.length; ++i) {
      output = output.replaceAll(
          '${HTLexicon.bracesLeft}$i${HTLexicon.bracesRight}',
          '${HTLexicon.stringInterpolationStart}${interpolation[i]}${HTLexicon.stringInterpolationEnd}');
    }
    return "'$output'";
  }

  @override
  String visitGroupExpr(GroupExpr expr) {
    final inner = formatAst(expr.inner);
    return '${HTLexicon.parenthesesLeft}$inner${HTLexicon.parenthesesRight}';
  }

  @override
  String visitSpreadExpr(SpreadExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.spreadSyntax);
    final valueString = formatAst(expr.value);
    output.write(valueString);
    return output.toString();
  }

  @override
  String visitListExpr(ListExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.bracketsLeft);
    output.write(
        expr.list.map((item) => formatAst(item)).join('${HTLexicon.comma} '));
    output.write(HTLexicon.bracketsRight);
    return output.toString();
  }

  // @override
  // String visitMapExpr(MapExpr expr) {
  //   final output = StringBuffer();
  //   output.write(HTLexicon.curlyLeft);
  //   if (expr.map.keys.isNotEmpty) {
  //     output.writeln();
  //     ++_curIndentCount;
  //     output.write(expr.map.entries
  //         .map((entry) =>
  //             '${formatAst(entry.key)}${HTLexicon.colon} ${formatAst(entry.value)}')
  //         .join('${HTLexicon.comma}\n'));
  //     --_curIndentCount;
  //   }
  //   output.write(curIndent);
  //   output.write(HTLexicon.curlyRight);
  //   return output.toString();
  // }

  @override
  String visitIdentifierExpr(IdentifierExpr expr) {
    return expr.id;
  }

  @override
  String visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    final valueString = formatAst(expr.value);
    return '${expr.op}$valueString';
  }

  @override
  String visitBinaryExpr(BinaryExpr expr) {
    final leftString = formatAst(expr.left);
    final rightString = formatAst(expr.right);
    return '$leftString ${expr.op} $rightString';
  }

  @override
  String visitTernaryExpr(TernaryExpr expr) {
    final condition = formatAst(expr.condition);
    final thenBranch = formatAst(expr.thenBranch);
    final elseBranch = formatAst(expr.elseBranch);
    return '$condition ${HTLexicon.condition} $thenBranch ${HTLexicon.elseBranch} $elseBranch';
  }

  @override
  String visitTypeExpr(TypeExpr expr) {
    final output = StringBuffer();
    output.write(expr.id);
    if (expr.arguments.isNotEmpty) {
      output.write(HTLexicon.typesBracketLeft);
      for (final type in expr.arguments) {
        final typeString = visitTypeExpr(type);
        output.write(typeString);
      }
      output.write(HTLexicon.typesBracketRight);
    }
    if (expr.isNullable) {
      output.write(HTLexicon.nullable);
    }
    return output.toString();
  }

  @override
  String visitParamTypeExpr(ParamTypeExpr expr) {
    final output = StringBuffer();
    var isOptional = false;
    var isNamed = false;
    if (expr.id != null) {
      if (!isNamed) {
        isNamed = true;
        output.write(HTLexicon.bracesLeft);
      }
      output.write('${expr.id}${HTLexicon.colon} ');
    }
    if (expr.isOptional && !isOptional) {
      isOptional = true;
      output.write(HTLexicon.bracketsLeft);
    }
    final typeString = visitTypeExpr(expr.declType);
    output.write(typeString);
    return output.toString();
  }

  @override
  String visitFunctionTypeExpr(FuncTypeExpr expr) {
    final output = StringBuffer();
    output.write('${HTLexicon.kFun} ${HTLexicon.parenthesesLeft}');
    output.write(expr.paramTypes
        .map((param) => visitParamTypeExpr(param))
        .join('${HTLexicon.comma} '));
    if (expr.hasOptionalParam) {
      output.write(HTLexicon.bracketsRight);
    } else if (expr.hasNamedParam) {
      output.write(HTLexicon.bracesRight);
    }
    output.write('${HTLexicon.parenthesesRight} ${HTLexicon.singleArrow} ');
    final returnTypeString = visitTypeExpr(expr.returnType);
    output.write(returnTypeString);
    return output.toString();
  }

  @override
  String visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {
    return expr.id.id;
  }

  @override
  String visitCallExpr(CallExpr expr) {
    final output = StringBuffer();
    final calleeString = formatAst(expr.callee);
    output.write('$calleeString${HTLexicon.parenthesesLeft}');
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      final arg = expr.positionalArgs[i];
      final argString = formatAst(arg);
      output.write(argString);
      if ((i < expr.positionalArgs.length - 1) || expr.namedArgs.isNotEmpty) {
        output.write('${HTLexicon.comma} ');
      }
    }
    if (expr.namedArgs.isNotEmpty) {
      output.write(expr.namedArgs.entries
          .toList()
          .map((entry) =>
              '${entry.key}${HTLexicon.colon} ${formatAst(entry.value)}')
          .join('${HTLexicon.comma} '));
    }
    output.write(HTLexicon.parenthesesRight);
    return output.toString();
  }

  @override
  String visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    final valueString = formatAst(expr.value);
    return '$valueString${expr.op}';
  }

  @override
  String visitMemberExpr(MemberExpr expr) {
    final collectionString = formatAst(expr.object);
    final keyString = formatAst(expr.key);
    return '$collectionString${HTLexicon.memberGet}$keyString';
  }

  @override
  String visitMemberAssignExpr(MemberAssignExpr expr) {
    final collectionString = formatAst(expr.object);
    final keyString = visitIdentifierExpr(expr.key);
    final valueString = formatAst(expr.value);
    return '$collectionString${HTLexicon.memberGet}$keyString ${HTLexicon.assign} $valueString';
  }

  @override
  String visitSubExpr(SubExpr expr) {
    final collectionString = formatAst(expr.object);
    final keyString = formatAst(expr.key);
    return '$collectionString${HTLexicon.bracketsLeft}$keyString${HTLexicon.bracketsRight}';
  }

  @override
  String visitSubAssignExpr(SubAssignExpr expr) {
    final collectionString = formatAst(expr.array);
    final keyString = formatAst(expr.key);
    final valueString = formatAst(expr.value);
    return '$collectionString${HTLexicon.bracketsLeft}$keyString${HTLexicon.bracketsRight} ${HTLexicon.assign} $valueString';
  }

  @override
  String visitAssertStmt(AssertStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kAssert} ');
    final exprString = formatAst(stmt.expr);
    output.write(exprString);
    return output.toString();
  }

  @override
  String visitExprStmt(ExprStmt stmt) {
    final output = StringBuffer();
    final exprString = formatAst(stmt.expr);
    output.write(exprString);
    return output.toString();
  }

  @override
  String visitBlockStmt(BlockStmt block) {
    final output = StringBuffer();
    if (block.statements.isNotEmpty) {
      output.writeln(' ${HTLexicon.bracesLeft}');
      ++_curIndentCount;
      for (final stmt in block.statements) {
        final stmtString = formatAst(stmt);
        if (stmtString.isNotEmpty) {
          output.write(curIndent);
          output.writeln(stmtString);
        }
      }
      --_curIndentCount;
      output.write(curIndent);
      output.write(HTLexicon.bracesRight);
    } else {
      output.write(' ${HTLexicon.bracesLeft}${HTLexicon.bracesRight}');
    }
    return output.toString();
  }

  @override
  String visitReturnStmt(ReturnStmt stmt) {
    final output = StringBuffer();
    output.write(HTLexicon.kReturn);
    if (stmt.value != null) {
      final valueString = formatAst(stmt.value!);
      output.write(' $valueString');
    }
    return output.toString();
  }

  @override
  String visitIfStmt(IfStmt ifStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kIf} ${HTLexicon.parenthesesLeft}');
    final conditionString = formatAst(ifStmt.condition);
    output.write('$conditionString${HTLexicon.parenthesesRight} ');
    final thenBranchString = formatAst(ifStmt.thenBranch);
    output.write(thenBranchString);
    if ((ifStmt.elseBranch is IfStmt) || (ifStmt.elseBranch is BlockStmt)) {
      output.write(' ${HTLexicon.kElse} ');
      final elseBranchString = formatAst(ifStmt.elseBranch!);
      output.write(elseBranchString);
    } else if (ifStmt.elseBranch != null) {
      output.writeln(' ${HTLexicon.kElse} ${HTLexicon.bracesLeft}');
      ++_curIndentCount;
      output.write(curIndent);
      final elseBranchString = formatAst(ifStmt.elseBranch!);
      output.writeln(elseBranchString);
      --_curIndentCount;
      output.write(curIndent);
      output.write(HTLexicon.bracesRight);
    }
    return output.toString();
  }

  @override
  String visitWhileStmt(WhileStmt whileStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kWhile} ');
    final conditionString = formatAst(whileStmt.condition);
    output.write('$conditionString ');
    final loopString = formatAst(whileStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitDoStmt(DoStmt doStmt) {
    final output = StringBuffer();
    output.write(HTLexicon.kDo);
    final loopString = formatAst(doStmt.loop);
    output.write(loopString);
    if (doStmt.condition != null) {
      final conditionString = formatAst(doStmt.condition!);
      output.write(' ${HTLexicon.kWhile} ');
      output.write(conditionString);
    }
    return output.toString();
  }

  @override
  String visitForStmt(ForStmt forStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kFor} ');
    if (forStmt.hasBracket) {
      output.write(HTLexicon.parenthesesLeft);
    }
    final declString = forStmt.init != null ? formatAst(forStmt.init!) : '';
    final conditionString =
        forStmt.condition != null ? formatAst(forStmt.condition!) : '';
    final incrementString =
        forStmt.increment != null ? formatAst(forStmt.increment!) : '';
    output.write(
        '$declString${HTLexicon.semicolon} $conditionString${HTLexicon.semicolon} $incrementString');
    if (forStmt.hasBracket) {
      output.write('${HTLexicon.parenthesesRight} ');
    }
    final loopString = formatAst(forStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitForRangeStmt(ForRangeStmt forInStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kFor} ');
    if (forInStmt.hasBracket) {
      output.write(HTLexicon.parenthesesLeft);
    }
    final declString = formatAst(forInStmt.iterator);
    final collectionString = formatAst(forInStmt.collection);
    output.write('$declString ${HTLexicon.kIn} $collectionString');
    if (forInStmt.hasBracket) {
      output.write('${HTLexicon.parenthesesRight} ');
    }
    final stmtString = formatAst(forInStmt.loop);
    output.write(stmtString);
    return output.toString();
  }

  @override
  String visitWhenStmt(WhenStmt stmt) {
    final output = StringBuffer();
    output.write(HTLexicon.kWhen);
    if (stmt.condition != null) {
      final conditionString = formatAst(stmt.condition!);
      output.write(
          ' ${HTLexicon.parenthesesLeft}$conditionString${HTLexicon.parenthesesRight}');
    }
    output.writeln(' ${HTLexicon.bracesLeft}');
    ++_curIndentCount;
    for (final option in stmt.cases.keys) {
      output.write(curIndent);
      final optionString = formatAst(option);
      output.write('$optionString ${HTLexicon.singleArrow} ');
      final branchString = formatAst(stmt.cases[option]!);
      output.writeln(branchString);
    }
    if (stmt.elseBranch != null) {
      final elseBranchString = formatAst(stmt.elseBranch!);
      output.write(curIndent);
      output.writeln(
          '${HTLexicon.kElse} ${HTLexicon.singleArrow} $elseBranchString');
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.bracesRight);
    return output.toString();
  }

  @override
  String visitBreakStmt(BreakStmt stmt) {
    return stmt.keyword.lexeme;
  }

  @override
  String visitContinueStmt(ContinueStmt stmt) {
    return stmt.keyword.lexeme;
  }

  @override
  String visitImportExportDecl(ImportExportDecl stmt) {
    final output = StringBuffer();
    if (!stmt.isExported) {
      output.write('${HTLexicon.kImport} ');
      if (stmt.showList.isNotEmpty) {
        output.write('${HTLexicon.bracesLeft} ');
        output.write(stmt.showList.join('${HTLexicon.comma} '));
        output.write(' ${HTLexicon.bracesRight} ${HTLexicon.kFrom} ');
      }
      output.write(
          '${HTLexicon.singleQuotationLeft}${stmt.fromPath}${HTLexicon.singleQuotationRight}');
      if (stmt.alias != null) {
        output.write(' ${HTLexicon.kAs} ${stmt.alias}');
      }
    } else {
      output.write('${HTLexicon.kExport} ');
      if (stmt.fromPath == null) {
        output.write(stmt.showList.join('${HTLexicon.comma} '));
      } else {
        if (stmt.showList.isNotEmpty) {
          output.write('${HTLexicon.bracesLeft} ');
          output.write(stmt.showList.join('${HTLexicon.comma} '));
          output.write(' ${HTLexicon.bracesRight} ${HTLexicon.kFrom} ');
        }
        output.write(
            '${HTLexicon.singleQuotationLeft}${stmt.fromPath}${HTLexicon.singleQuotationRight}');
      }
    }
    return output.toString();
  }

  @override
  String visitNamespaceDecl(NamespaceDecl stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kNamespace} ${stmt.id.id} ');
    final blockString = visitBlockStmt(stmt.definition);
    output.write(blockString);
    return output.toString();
  }

  @override
  String visitTypeAliasDecl(TypeAliasDecl stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kType} ${stmt.id} ${HTLexicon.assign} ');
    final valueString = formatAst(stmt.value);
    output.write(valueString);
    return output.toString();
  }

  @override
  String visitConstDecl(ConstDecl stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kConst} ${HTLexicon.assign} ');
    final valueString = formatAst(stmt.constExpr);
    output.write(valueString);
    return output.toString();
  }

  @override
  String visitVarDecl(VarDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    if (stmt.isStatic) {
      output.write('${HTLexicon.kStatic} ');
    }
    if (!stmt.isMutable) {
      output.write('${HTLexicon.kConst} ');
    }
    // else if (stmt.typeInferrence) {
    //   output.write('${HTLexicon.LET} ');
    // }
    else {
      output.write('${HTLexicon.kVar} ');
    }
    output.write('${stmt.id}');
    if (stmt.declType != null) {
      final typeString = formatAst(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = formatAst(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    return output.toString();
  }

  @override
  String visitParamDecl(ParamDecl stmt) {
    final output = StringBuffer();
    output.write('${stmt.id}');
    if (stmt.declType != null) {
      final typeString = formatAst(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = formatAst(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    return output.toString();
  }

  @override
  String visitReferConstructCallExpr(RedirectingConstructorCallExpr stmt) {
    final output = StringBuffer();
    output.write(stmt.callee.id);
    if (stmt.key != null) {
      output.write('${HTLexicon.memberGet}${stmt.key}');
    }
    return output.toString();
  }

  String printParamDecls(List<ParamDecl> params) {
    final output = StringBuffer();
    var isOptional = false;
    var isNamed = false;
    output.write(HTLexicon.parenthesesLeft);
    for (var i = 0; i < params.length; ++i) {
      final param = params[i];
      if (param.isOptional) {
        if (!isOptional) {
          isOptional = true;
          output.write(HTLexicon.bracketsLeft);
        }
        if (param.isVariadic) {
          output.write('${HTLexicon.variadicArgs} ');
        }
      } else if (param.isNamed && !isNamed) {
        isNamed = true;
        output.write(HTLexicon.bracketsLeft);
      }
      final paramString = visitParamDecl(param);
      output.write(paramString);
      if (i < params.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write(HTLexicon.parenthesesRight);
    return output.toString();
  }

  @override
  String visitFuncDecl(FuncDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    if (stmt.isStatic) {
      output.write('${HTLexicon.kStatic} ');
    }
    switch (stmt.category) {
      case FunctionCategory.normal:
      case FunctionCategory.method:
      case FunctionCategory.literal:
        output.write(HTLexicon.kFun);
        break;
      case FunctionCategory.constructor:
        output.write(HTLexicon.kFactory);
        break;
      case FunctionCategory.factoryConstructor:
        output.write(HTLexicon.kFactory);
        break;
      case FunctionCategory.getter:
        output.write(HTLexicon.kGet);
        break;
      case FunctionCategory.setter:
        output.write(HTLexicon.kSet);
        break;
      default:
        break;
    }
    if (stmt.externalTypeId != null) {
      output.write(
          ' ${HTLexicon.bracketsLeft}${stmt.externalTypeId}${HTLexicon.bracketsRight}');
    }
    if (stmt.id != null) {
      output.write(' ${stmt.id}');
    }
    final paramDeclString = printParamDecls(stmt.paramDecls);
    output.write(paramDeclString);
    output.write(' ');
    if (stmt.returnType != null) {
      output.write('${HTLexicon.singleArrow} ');
      final returnTypeString = visitTypeExpr(stmt.returnType!);
      output.write('$returnTypeString ');
    } else if (stmt.redirectingCtorCallExpr != null) {
      output.write('${HTLexicon.colon} ');
      final referCtorString =
          visitReferConstructCallExpr(stmt.redirectingCtorCallExpr!);
      output.write('$referCtorString ');
    }
    if (stmt.definition != null) {
      final blockString = formatAst(stmt.definition!);
      output.write(blockString);
    }
    return output.toString();
  }

  @override
  String visitClassDecl(ClassDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    if (stmt.isAbstract) {
      output.write('${HTLexicon.kAbstract} ');
    }
    output.write('${HTLexicon.kClass} ${stmt.id} ');
    if (stmt.superType != null) {
      final superClassTypeString = visitTypeExpr(stmt.superType!);
      output.write('${HTLexicon.kExtends} $superClassTypeString ');
    }
    final blockString = visitBlockStmt(stmt.definition);
    output.write(blockString);
    return output.toString();
  }

  @override
  String visitEnumDecl(EnumDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    output.writeln('${HTLexicon.kEnum} ${stmt.id} ${HTLexicon.bracesLeft}');
    ++_curIndentCount;
    output.write(stmt.enumerations.join('${HTLexicon.comma}\n'));
    output.writeln();
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.bracesRight);
    return output.toString();
  }

  @override
  String visitStructDecl(StructDecl stmt) {
    final output = StringBuffer();
    output.writeln('${HTLexicon.kStruct} ${stmt.id} ${HTLexicon.bracesLeft}');
    ++_curIndentCount;
    for (var i = 0; i < stmt.definition.length; ++i) {
      final valueString = formatAst(stmt.definition[i]);
      output.writeln(valueString);
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.bracesRight);
    return output.toString();
  }

  @override
  String visitStructObjField(StructObjField field) {
    final output = StringBuffer();
    if (field.key != null) {
      output.write('${field.key}${HTLexicon.colon} ');
      final valueString = formatAst(field.value!);
      output.write(valueString);
    } else if (field.isSpread) {
      output.write(HTLexicon.spreadSyntax);
      final valueString = formatAst(field.value!);
      output.write(valueString);
    } else {
      for (final comment in field.precedingComments) {
        output.writeln(comment.content);
      }
    }
    return output.toString();
  }

  @override
  String visitStructObjExpr(StructObjExpr obj) {
    final output = StringBuffer();
    output.writeln(HTLexicon.bracesLeft);
    ++_curIndentCount;
    for (var i = 0; i < obj.fields.length; ++i) {
      final field = obj.fields[i];
      final fieldString = visitStructObjField(field);
      output.write(fieldString);
      if (i < obj.fields.length - 1) {
        output.write(HTLexicon.comma);
      }
      output.writeln();
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.bracesRight);
    return output.toString();
  }
}
