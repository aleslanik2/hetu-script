## 0.3.5

- Added const declaration for boolean, int, float and string.
- Fixed comment parsing problems. Now comment could be written almost anywhere without affect parser.

## 0.3.4

- Added for...of syntax for iterate through values of Map or struct literal.
- When statement now can also be used as expression.
- If null syntax: '?.', '??', '??='.

## 0.3.3

- Added spread syntax on function call argument, list and struct literal
- Added short identifier for struct literal

## 0.3.2

- Added [isStrictMode] for interpreter, in non strict mode, if/while/do and and/or expression can have a non boolean value for condition check.
- Added Future.then external method for script to handle with Dart Futures.

## 0.3.1

- **Changed the external function typedef in Dart, added namespace as first arg when called.**

## 0.3.0

- Command line tool and file system context support moved to another package: [hetu_script_dev_tools].
- Added a new kind of external binding: external method on normal classes
- Added support for literal function expression with no keyword.
- Added struct literal and prototype based object system. **The map literal is replaced with struct literal.**

## 0.2.0

- Analyzer can check for syntactic errors now.
- Added IDE support for analyzer and formatter.
- Compile source into bytecode and load it at another time to skip parsing and compile process.

## 0.1.3

- Named constructor can refer to default constructor: 'construct name(): this()'.
- Feature: Single expression 'function: fun add(a, b) => a + b'.
- Feature: Type alias: 'type MyFuncType = fun (num, num) -> num'.

## 0.1.2

- Added Analyzer and Formatter utility classes (WIP).
- Added Type expression and related assignment operations.
- Feature: Added default implementation of 'toJson' on instances.

## 0.1.1

- Feature: Sequenced constructor calling through super classes.
- Feature: 'super' keyword with instance method, for calling super class method.
- Feature: 'as' & 'is' operator, with super class checking & casting.
- Feature: Full funtion type check with parameters and return type.

## 0.1.0

- Refactor: Changed default interpreter into bytecode machine.
- Feature: String interpolation.
- Feature: Now fully support nested function and literal function.
- Feature: Added ++, -- post and pre operators, and +=, -=, \*=, /= operators.
- Feature: Full support on While, Do loops, classic for(init;condition;increment), for...in, when statement (works like switch).
- Feature: Ternary operator: 'conditon ? true : false'.
- Feature: Interpreter function for bind Dart Function Typedef.

## 0.0.5

- Refactor: Migrate to null safety.
- Feature: Literal function expression (anonymous function).
- Feature: Named function parameters.
- Feature: Support literal hexadecimal numbers.

## 0.0.1

- Initial version, hello world!
