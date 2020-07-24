import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'token.dart';
import 'common.dart';
import 'interpreter.dart';

enum ParseStyle {
  /// 程序脚本使用完整的标点符号规则，包括各种括号、逗号和分号
  ///
  /// 程序脚本中只能出现变量、类和函数的声明
  ///
  /// 程序脚本中必有一个叫做main的完整函数作为入口
  library,

  /// 函数语句块中只能出现变量声明、控制语句和函数调用
  program,

  /// 类定义中只能出现变量和函数的声明
  classDefinition,
}

/// 负责对Token列表进行语法分析并生成语句列表
///
/// 语法定义如下
///
/// <程序>    ::=   <导入语句> | <变量声明>
///
/// <变量声明>      ::=   <变量声明> | <函数定义> | <类定义>
///
/// <语句块>    ::=   "{" <语句> { <语句> } "}"
///
/// <语句>      ::=   <声明> | <表达式> ";"
///
/// <表达式>    ::=   <标识符> | <单目> | <双目> | <三目>
///
/// <运算符>    ::=   <运算符>
class Parser {
  final List<Token> _tokens = [];
  var _position = 0;
  Interpreter _context;
  String _curClassName;

  static const List<String> _patternImport = [HS_Common.Import, HS_Common.Str];
  static const List<String> _patternVarDecl = [HS_Common.Identifier, HS_Common.Identifier, HS_Common.Semicolon];
  static const List<String> _patternInit = [HS_Common.Identifier, HS_Common.Identifier, HS_Common.Assign];
  static const List<String> _patternFuncDecl = [HS_Common.Identifier, HS_Common.Identifier, HS_Common.RoundLeft];
  static const List<String> _patternAssign = [HS_Common.Identifier, HS_Common.Assign];
  static const List<String> _patternIf = [HS_Common.If, HS_Common.RoundLeft];
  static const List<String> _patternWhile = [HS_Common.While, HS_Common.RoundLeft];

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 如果consume为true，则向前移动Token指针，并且会在不符合预期时记录错误
  bool expect(List<String> tokenTypes, {bool consume = false}) {
    var result = true;
    for (var i = 0; i < tokenTypes.length; ++i) {
      if (consume) {
        if (curTok.type != tokenTypes[i]) {
          throw HSErr_Expected(tokenTypes[i], curTok.lexeme, curTok.line, curTok.column);
        }
        ++_position;
      } else {
        if (peek(i).type != tokenTypes[i]) {
          result = false;
          break;
        }
      }
    }
    return result;
  }

  Token advance(int distance) {
    _position += distance;
    return curTok;
  }

  Token peek(int pos) {
    if ((_position + pos) < _tokens.length) {
      return _tokens[_position + pos];
    } else {
      return Token.EOF;
    }
  }

  Token get curTok => peek(0);

  List<Stmt> parse(
    List<Token> tokens, {
    Interpreter interpreter,
    ParseStyle style = ParseStyle.library,
  }) {
    _tokens.clear();
    _tokens.addAll(tokens);
    _position = 0;

    _context = interpreter ?? globalInterpreter;

    var statements = <Stmt>[];
    while (curTok.type != HS_Common.EOF) {
      statements.add(_parseStmt(style: style));
    }
    return statements;
  }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  Expr _parseExpr() {
    return _parseAssignmentExpr();
  }

  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  Expr _parseAssignmentExpr() {
    Expr expr = _parseLogicalOrExpr();

    if (HS_Common.Assignment.contains(curTok.type)) {
      Token op = curTok;
      advance(1);
      Expr value = _parseAssignmentExpr();

      if (expr is VarExpr) {
        Token name = expr.name;
        return AssignExpr(name, op, value);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value);
      }

      throw HSErr_InvalidLeftValue('', op.line, op.column);
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  Expr _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == HS_Common.Or) {
      var op = curTok;
      advance(1);
      var right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  Expr _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok.type == HS_Common.And) {
      var op = curTok;
      advance(1);
      var right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  Expr _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    while (HS_Common.Equality.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  Expr _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    while (HS_Common.Relational.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseAdditiveExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 加法 +, -，优先级 13，左合并
  Expr _parseAdditiveExpr() {
    var expr = _parseMultiplicativeExpr();
    while (HS_Common.Additive.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseMultiplicativeExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 乘法 *, /, %，优先级 14，左合并
  Expr _parseMultiplicativeExpr() {
    var expr = _parseUnaryPrefixExpr();
    while (HS_Common.Multiplicative.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseUnaryPrefixExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 前缀 -e, !e，优先级 15，不能合并
  Expr _parseUnaryPrefixExpr() {
    // 因为是前缀所以不能像别的表达式那样先进行下一级的分析
    Expr expr;
    if (HS_Common.UnaryPrefix.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      expr = UnaryExpr(op, _parseUnaryPostfixExpr());
    } else {
      expr = _parseUnaryPostfixExpr();
    }
    return expr;
  }

  /// 后缀 e., e[], e()，优先级 16，取属性不能合并，下标和函数调用可以右合并
  Expr _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    //多层函数调用可以合并
    while (true) {
      if (curTok.lexeme == HS_Common.RoundLeft) {
        advance(1);
        var params = <Expr>[];
        while ((curTok.type != HS_Common.RoundRight) && (curTok.type != HS_Common.EOF)) {
          params.add(_parseExpr());
          if (curTok.type == HS_Common.Comma) {
            advance(1);
          }
        }
        expr = CallExpr(expr, params);
        expect([HS_Common.RoundRight], consume: true);
      } else if (curTok.lexeme == HS_Common.Dot) {
        advance(1);
        if (curTok.type == HS_Common.Identifier) {
          Token name = curTok;
          expr = MemberGetExpr(expr, name);
          advance(1);
        } else {
          throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
        }
      } else {
        break;
      }
    }

    return expr;
  }

  /// 只有一个Token的简单表达式
  Expr _parsePrimaryExpr() {
    Expr expr;
    if (HS_Common.Literals.contains(curTok.type)) {
      int index;
      if (curTok.literal is num) {
        index = _context.addLiteral(curTok.literal);
      } else if (curTok.literal is bool) {
        index = _context.addLiteral(curTok.literal);
      } else if (curTok.literal is String) {
        index = _context.addLiteral(HS_Common.convertEscapeCode(curTok.literal));
      }
      expr = LiteralExpr(index, curTok.line, curTok.column);
      advance(1);
    } else if (curTok.type == HS_Common.This) {
      expr = ThisExpr(curTok);
      advance(1);
    } else if (curTok.type == HS_Common.Identifier) {
      expr = VarExpr(curTok);
      advance(1);
    } else if (curTok.type == HS_Common.RoundLeft) {
      advance(1);
      var innerExpr = _parseExpr();
      expect([HS_Common.RoundRight], consume: true);
      expr = GroupExpr(innerExpr);
    } else {
      throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
    }
    return expr;
  }

  Stmt _parseStmt({ParseStyle style = ParseStyle.library}) {
    bool is_extern;
    if (curTok.type == HS_Common.External) {
      is_extern = true;
      advance(1);
    } else {
      is_extern = false;
    }
    bool is_static;
    if (curTok.type == HS_Common.Static) {
      is_static = true;
      advance(1);
    } else {
      is_static = false;
    }
    switch (style) {
      case ParseStyle.library:
        {
          if (expect(_patternImport)) {
            return _parseImportStmt();
          }
          // 如果是变量声明
          else if (expect(_patternVarDecl)) {
            return _parseVarStmt();
          } // 如果是带初始化语句的变量声明
          else if (expect(_patternInit)) {
            return _parseVarInitStmt();
          } // 如果是函数声明
          else if (expect(_patternFuncDecl)) {
            return _parseFunctionStmt(isExtern: is_extern, isStatic: is_static);
          } // 如果是类声明
          else if (expect([HS_Common.Class, HS_Common.Identifier, HS_Common.CurlyLeft]) ||
              expect([
                HS_Common.Class,
                HS_Common.Identifier,
                HS_Common.Extends,
                HS_Common.Identifier,
                HS_Common.CurlyLeft
              ])) {
            return _parseClassStmt();
          } else {
            throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
          }
        }
        break;
      case ParseStyle.program:
        {
          // 如果是变量声明
          if (expect(_patternVarDecl)) {
            return _parseVarStmt();
          } // 如果是带初始化语句的变量声明
          else if (expect(_patternInit)) {
            return _parseVarInitStmt();
          } // 如果是赋值语句
          else if (expect(_patternAssign)) {
            return _parseAssignStmt();
          } // 如果是跳出语句
          else if (curTok.type == HS_Common.Break) {
            return BreakStmt();
          } // 如果是返回语句
          else if (curTok.type == HS_Common.Return) {
            return _parseReturnStmt();
          } // 如果是If语句
          else if (expect(_patternIf)) {
            return _parseIfStmt();
          } // 如果是While语句
          else if (expect(_patternWhile)) {
            return _parseWhileStmt();
          } // 其他语句都认为是表达式
          else {
            return _parseExprStmt();
          }
        }
        break;
      case ParseStyle.classDefinition:
        {
          // 如果是变量声明
          if (expect(_patternVarDecl)) {
            return _parseVarStmt();
          } // 如果是带初始化语句的变量声明
          else if (expect(_patternInit)) {
            return _parseVarInitStmt();
          } // 如果是构造函数
          // TODO：命名的构造函数
          else if ((curTok.lexeme == _curClassName) && (peek(1).type == HS_Common.RoundLeft)) {
            return _parseConstructorStmt();
          } // 如果是函数声明
          else if (expect(_patternFuncDecl)) {
            return _parseFunctionStmt(isExtern: is_extern, isStatic: is_static);
          } else {
            throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
          }
        }
        break;
    }
    return null;
  }

  List<Stmt> _parseBlock({ParseStyle style = ParseStyle.library}) {
    var stmts = <Stmt>[];
    while ((curTok.type != HS_Common.CurlyRight) && (curTok.type != HS_Common.EOF)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HS_Common.CurlyRight], consume: true);
    return stmts;
  }

  BlockStmt _parseBlockStmt({ParseStyle style = ParseStyle.library}) {
    var stmts = <Stmt>[];
    while ((curTok.type != HS_Common.CurlyRight) && (curTok.type != HS_Common.EOF)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HS_Common.CurlyRight], consume: true);
    return BlockStmt(stmts);
  }

  ImportStmt _parseImportStmt() {
    advance(1);
    var stmt = ImportStmt(curTok.literal);
    advance(1);
    expect([HS_Common.Semicolon], consume: true);
    return stmt;
  }

  /// 无初始化的变量声明语句
  VarStmt _parseVarStmt() {
    if (!HS_Common.BuildInTypes.contains(curTok.lexeme)) {
      throw HSErr_Undefined(curTok.lexeme, curTok.line, curTok.column);
    }
    var typename = curTok;
    var varname = peek(1);
    // 之前已经校验过了所以这里直接跳过
    advance(2);
    // 语句一定以分号结尾
    expect([HS_Common.Semicolon], consume: true);
    return VarStmt(typename, varname, null);
  }

  /// 有初始化的变量声明语句
  VarStmt _parseVarInitStmt() {
    VarStmt stmt;
    var typename = curTok;
    var varname = peek(1);
    // 之前已经校验过等于号了所以这里直接跳过
    advance(3);
    var initializer = _parseExpr();
    // 语句一定以分号结尾
    expect([HS_Common.Semicolon], consume: true);
    return VarStmt(typename, varname, initializer);
  }

  /// 为了避免涉及复杂的左值右值问题，赋值语句在河图中不作为表达式处理
  /// 而是分成直接赋值，取值后复制和取属性后复制
  ExprStmt _parseAssignStmt() {
    var name = curTok;
    // 之前已经校验过等于号了所以这里直接跳过
    advance(1);
    var assignTok = curTok;
    advance(1);
    var value = _parseExpr();
    // 语句一定以分号结尾
    expect([HS_Common.Semicolon], consume: true);
    var expr = AssignExpr(name, assignTok, value);
    return ExprStmt(expr);
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句一定以分号结尾
    expect([HS_Common.Semicolon], consume: true);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = curTok;
    advance(1);
    Expr expr;
    if (curTok.type != HS_Common.Semicolon) {
      expr = _parseExpr();
    }
    expect([HS_Common.Semicolon], consume: true);
    return ReturnStmt(keyword, expr);
  }

  IfStmt _parseIfStmt() {
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    var condition = _parseExpr();
    expect([HS_Common.RoundRight], consume: true);
    Stmt thenBranch;
    if (curTok.type == HS_Common.CurlyLeft) {
      advance(1);
      thenBranch = _parseBlockStmt(style: ParseStyle.program);
    } else {
      thenBranch = _parseStmt(style: ParseStyle.program);
    }
    Stmt elseBranch;
    if (curTok.type == HS_Common.Else) {
      advance(1);
      if (curTok.type == HS_Common.CurlyLeft) {
        advance(1);
        elseBranch = _parseBlockStmt(style: ParseStyle.program);
      } else {
        elseBranch = _parseStmt(style: ParseStyle.program);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch);
  }

  WhileStmt _parseWhileStmt() {
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    var condition = _parseExpr();
    advance(1);
    Stmt loop;
    if (curTok.type == HS_Common.CurlyLeft) {
      advance(1);
      loop = _parseBlockStmt(style: ParseStyle.program);
    } else {
      loop = _parseStmt(style: ParseStyle.program);
    }
    return WhileStmt(condition, loop);
  }

  List<VarStmt> _parseParameters() {
    var result = <VarStmt>[];
    while ((curTok.type != HS_Common.RoundRight) && (curTok.type != HS_Common.EOF)) {
      if ((result.isNotEmpty) && (curTok.type == HS_Common.Comma)) {
        advance(1);
      }
      if (expect([HS_Common.Identifier, HS_Common.Identifier, HS_Common.Comma]) ||
          expect([HS_Common.Identifier, HS_Common.Identifier, HS_Common.RoundRight])) {
        if (HS_Common.ParametersTypes.contains(curTok.lexeme)) {
          //TODO，参数默认值、可选参数、命名参数
          result.add(VarStmt(curTok, peek(1), null));
        } else {
          throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
        }
      } else {
        throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
      }
      advance(2);
    }
    expect([HS_Common.RoundRight], consume: true);
    return result;
  }

  FuncStmt _parseFunctionStmt({bool isExtern = false, bool isStatic = false}) {
    if (!HS_Common.FunctionReturnTypes.contains(curTok.lexeme)) {
      throw HSErr_Undefined(curTok.lexeme, curTok.line, curTok.column);
    }
    var return_type = curTok.lexeme;
    var func_name = peek(1);
    // 之前已经校验过左括号了所以这里直接跳过
    advance(3);
    var params = <VarStmt>[];
    int arity;
    if (curTok.type == HS_Common.Any) {
      arity = -1;
      advance(1);
      expect([HS_Common.RoundRight], consume: true);
    } else {
      params = _parseParameters();
      arity = params.length;
    }
    var body = <Stmt>[];
    if (!isExtern) {
      // 处理函数定义部分的语句块
      expect([HS_Common.CurlyLeft], consume: true);
      body = _parseBlock(style: ParseStyle.program);
    } else {
      expect([HS_Common.Semicolon], consume: true);
    }
    return FuncStmt(return_type, func_name, params,
        arity: arity, definition: body, isExtern: isExtern, isStatic: isStatic);
  }

  FuncStmt _parseConstructorStmt() {
    var name = curTok;
    advance(2);
    var params = _parseParameters();
    expect([HS_Common.CurlyLeft], consume: true);
    var body = _parseBlock(style: ParseStyle.program);
    return FuncStmt(_curClassName, name, params, definition: body, className: _curClassName, isConstructor: true);
  }

  ClassStmt _parseClassStmt() {
    ClassStmt stmt;
    // 已经判断过了所以直接跳过Class关键字
    advance(1);
    var class_name = curTok;
    _curClassName = curTok.lexeme;
    VarExpr super_class;
    advance(1);
    if (curTok.type == HS_Common.Extends) {
      advance(1);
      super_class = VarExpr(curTok);
      advance(2);
    } else {
      advance(1);
    }

    var variables = <VarStmt>[];
    var methods = <FuncStmt>[];
    while ((curTok.type != HS_Common.CurlyRight) && (curTok.type != HS_Common.EOF)) {
      var stmt = _parseStmt(style: ParseStyle.classDefinition);
      if (stmt is VarStmt) {
        variables.add(stmt);
      } else if (stmt is FuncStmt) {
        methods.add(stmt);
      }
    }
    expect([HS_Common.CurlyRight], consume: true);

    stmt = ClassStmt(class_name, super_class, variables, methods);
    _curClassName = null;
    return stmt;
  }
}
