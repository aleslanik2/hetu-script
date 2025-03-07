// import '../source/source.dart';
import '../resource/resource_context.dart';
import '../error/error.dart';
// import '../error/error_handler.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../lexer/token.dart';

abstract class ParserConfig {}

class ParserConfigImpl implements ParserConfig {}

/// Abstract interface for handling a token list.
abstract class HTAbstractParser {
  /// The file current under processing, used in error message.
  String? get currrentFileName;

  String? get currentModuleName;

  HTResourceContext get sourceContext;

  int _line = 0;
  int _column = 0;
  int get line => _line;
  int get column => _column;

  final errors = <HTError>[];

  var tokPos = 0;

  late Token endOfFile;

  final List<Token> _tokens = [];

  void setTokens(List<Token> tokens) {
    tokPos = 0;
    _tokens.clear();
    _tokens.addAll(tokens);
    _line = 0;
    _column = 0;

    endOfFile = Token(
        Semantic.endOfFile,
        _tokens.isNotEmpty ? _tokens.last.line + 1 : 0,
        0,
        _tokens.isNotEmpty ? _tokens.last.offset + 1 : 0,
        0);
  }

  /// Get a token at a relative [distance] from current position.
  Token peek(int distance) {
    if ((tokPos + distance) < _tokens.length) {
      return _tokens[tokPos + distance];
    } else {
      return endOfFile;
    }
  }

  /// Search for parentheses right token that can closing the current one, return the token next to it.
  Token seekGroupClosing() {
    var current = curTok;
    late String closing;
    var distance = 0;
    var depth = 0;
    if (current.type == HTLexicon.parenthesesLeft) {
      closing = HTLexicon.parenthesesRight;
    } else if (current.type == HTLexicon.bracketsLeft) {
      closing = HTLexicon.bracketsRight;
    } else if (current.type == HTLexicon.bracesLeft) {
      closing = HTLexicon.bracesRight;
    } else if (current.type == HTLexicon.chevronsLeft) {
      closing = HTLexicon.chevronsRight;
    } else {
      return current;
    }
    void forward() {
      current = peek(distance);
    }

    do {
      forward();
      ++distance;
      if (current.type == HTLexicon.parenthesesLeft) {
        ++depth;
      } else if (depth > 0 && current.type == closing) {
        --depth;
      }
    } while ((depth > 0 || current.type != closing) &&
        current.type != Semantic.endOfFile);
    return peek(distance);
  }

  /// Search for a token type, return the token next to it.
  Token seek(String type) {
    late Token current;
    var distance = 0;
    do {
      current = peek(distance);
      ++distance;
    } while (current.type != type && curTok.type != Semantic.endOfFile);
    return peek(distance);
  }

  /// Check current token and some tokens after it to see if the [types] match,
  /// return a boolean result.
  /// If [consume] is true, will advance.
  bool expect(List<String> types, {bool consume = false}) {
    for (var i = 0; i < types.length; ++i) {
      if (peek(i).type != types[i]) {
        return false;
      }
    }
    if (consume) {
      advance(types.length);
    }
    return true;
  }

  /// If the token match the [type] provided, advance 1
  /// and return the original token. If not, generate an error.
  Token match(String type) {
    if (curTok.type != type) {
      final err = HTError.unexpected(type, curTok.lexeme,
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    }

    return advance(1);
  }

  /// Advance till reach [distance], return the token at original position.
  Token advance(int distance) {
    tokPos += distance;
    _line = curTok.line;
    _column = curTok.column;
    return peek(-distance);
  }

  /// Get current token.
  Token get curTok => peek(0);
}
