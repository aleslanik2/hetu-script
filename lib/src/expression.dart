import 'token.dart';
import 'common.dart';

/// 抽象的访问者模式，包含访问表达式的抽象语法树的接口
///
///语句和表达式的区别在于：1，语句以";"结尾，而表达式没有";""
///
/// 2，访问语句返回void，访问表达式返回dynamic
///
/// 3，访问语句称作execute，访问表达式称作evaluate
///
/// 4，语句包含表达式，而表达式不包含语句
abstract class ExprVisitor {
  /// Null
  dynamic visitNullExpr(NullExpr expr);

  /// 字面量
  dynamic visitLiteralExpr(LiteralExpr expr);

  /// 数组
  dynamic visitListExpr(ListExpr expr);

  /// 数组
  dynamic visitMapExpr(MapExpr expr);

  /// 单目表达式
  dynamic visitUnaryExpr(UnaryExpr expr);

  /// 双目表达式
  dynamic visitBinaryExpr(BinaryExpr expr);

  /// 变量
  dynamic visitVarExpr(VarExpr expr);

  /// 类型
  // dynamic visitTypeExpr(TypeExpr expr);

  /// 括号表达式
  dynamic visitGroupExpr(GroupExpr expr);

  /// 赋值表达式，返回右值，执行顺序优先右边
  ///
  /// 因此，a = b = c 解析为 a = (b = c)
  dynamic visitAssignExpr(AssignExpr expr);

  /// 下标取值表达式
  dynamic visitSubGetExpr(SubGetExpr expr);

  /// 下标赋值表达式
  dynamic visitSubSetExpr(SubSetExpr expr);

  /// 属性取值表达式
  dynamic visitMemberGetExpr(MemberGetExpr expr);

  /// 属性赋值表达式
  dynamic visitMemberSetExpr(MemberSetExpr expr);

  /// 函数调用表达式，即便返回值是void的函数仍然还是表达式
  dynamic visitCallExpr(CallExpr expr);

  /// This表达式
  dynamic visitThisExpr(ThisExpr expr);
}

abstract class Expr {
  String get type;
  final int line;
  final int column;

  /// 取表达式右值，返回值本身
  dynamic accept(ExprVisitor visitor);

  Expr(this.line, this.column);
}

class NullExpr extends Expr {
  @override
  String get type => HS_Common.NullExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr(int line, int column) : super(line, column);
}

class LiteralExpr extends Expr {
  @override
  String get type => HS_Common.LiteralExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitLiteralExpr(this);

  int _constIndex;
  int get constantIndex => _constIndex;

  LiteralExpr(int constantIndex, int line, int column) : super(line, column) {
    _constIndex = constantIndex;
  }
}

class ListExpr extends Expr {
  @override
  String get type => HS_Common.ListExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitListExpr(this);

  List<Expr> list;

  ListExpr(this.list, int line, int column) : super(line, column) {
    list ??= [];
  }
}

class MapExpr extends Expr {
  @override
  String get type => HS_Common.MapExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMapExpr(this);

  Map<Expr, Expr> map;

  MapExpr(this.map, int line, int column) : super(line, column) {
    map ??= {};
  }
}

class UnaryExpr extends Expr {
  @override
  String get type => HS_Common.UnaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitUnaryExpr(this);

  /// 各种单目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  UnaryExpr(this.op, this.value) : super(op.line, op.column);
}

class BinaryExpr extends Expr {
  @override
  String get type => HS_Common.BinaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitBinaryExpr(this);

  /// 左值
  final Expr left;

  /// 各种双目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr right;

  BinaryExpr(this.left, this.op, this.right) : super(op.line, op.column);
}

class VarExpr extends Expr {
  @override
  String get type => HS_Common.VarExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitVarExpr(this);

  final Token name;

  VarExpr(this.name) : super(name.line, name.column);
}

class GroupExpr extends Expr {
  @override
  String get type => HS_Common.GroupExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitGroupExpr(this);

  final Expr inner;

  GroupExpr(this.inner) : super(inner.line, inner.column);
}

class AssignExpr extends Expr {
  @override
  String get type => HS_Common.AssignExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitAssignExpr(this);

  /// 变量名
  final Token variable;

  /// 各种赋值符号变体
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  AssignExpr(this.variable, this.op, this.value) : super(op.line, op.column);
}

class SubGetExpr extends Expr {
  @override
  String get type => HS_Common.SubGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final Expr collection;

  /// 索引
  final Expr key;

  SubGetExpr(this.collection, this.key) : super(collection.line, collection.column);
}

class SubSetExpr extends Expr {
  @override
  String get type => HS_Common.SubSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubSetExpr(this);

  /// 数组
  final Expr collection;

  /// 索引
  final Expr key;

  /// 值
  final Expr value;

  SubSetExpr(this.collection, this.key, this.value) : super(collection.line, collection.column);
}

class MemberGetExpr extends Expr {
  @override
  String get type => HS_Common.MemberGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberGetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  MemberGetExpr(this.collection, this.key) : super(collection.line, collection.column);
}

class MemberSetExpr extends Expr {
  @override
  String get type => HS_Common.MemberSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberSetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  /// 值
  final Expr value;

  MemberSetExpr(this.collection, this.key, this.value) : super(collection.line, collection.column);
}

class CallExpr extends Expr {
  @override
  String get type => HS_Common.CallExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitCallExpr(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final Expr callee;

  /// 函数声明的参数是parameter，调用时传入的变量叫argument
  final List<Expr> args;

  CallExpr(this.callee, this.args) : super(callee.line, callee.column);
}

class ThisExpr extends Expr {
  @override
  String get type => HS_Common.ThisExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitThisExpr(this);

  final Token keyword;

  ThisExpr(this.keyword) : super(keyword.line, keyword.column);
}
