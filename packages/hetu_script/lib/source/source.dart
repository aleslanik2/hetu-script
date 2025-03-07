import 'dart:math' as math;

import 'package:path/path.dart' as path;

// import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../shared/crc32b.dart';
import 'line_info.dart';

/// Code module types
enum SourceType {
  /// Module source can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// A script can have all statements and expressions, kind of like a funciton body.
  script,

  /// An expression.
  expression,

  /// Class can only have declarations (variables, functions).
  classDefinition,

  /// Struct can not have external members
  structDefinition,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  functionDefinition,
}

class HTSource {
  static const _anonymousScriptNameLengthLimit = 72;

  static const hetuModuleFileExtension = '.ht';
  static const hetuScriptFileExtension = '.hts';

  late String name;
  String get basename => path.basename(name);

  final bool isScript;

  String _content;
  String get content => _content;
  set content(String value) {
    _content = value;
    _lineInfo = LineInfo.fromContent(content);
  }

  LineInfo _lineInfo;
  LineInfo get lineInfo => _lineInfo;

  HTSource(String content, {String? name, this.isScript = false})
      : _content = content,
        _lineInfo = LineInfo.fromContent(content) {
    if (name != null) {
      this.name = name;
    } else {
      final crc32b = Crc32b.compute(content);
      final nameBuilder = StringBuffer();
      nameBuilder.write('${Semantic.anonymousScript}_$crc32b: ');
      var firstLine =
          content.trimLeft().replaceAll(RegExp(r'\s+'), ' ').trimRight();
      nameBuilder.write(firstLine.substring(
          0, math.min(_anonymousScriptNameLengthLimit, firstLine.length)));
      if (firstLine.length > _anonymousScriptNameLengthLimit) {
        nameBuilder.write('...');
      }
      this.name = nameBuilder.toString();
    }
  }
}
