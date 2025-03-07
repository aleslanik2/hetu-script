import '../shared/util.dart' as util;

/// The location of a character represented as a line and column pair.
class CharacterLocation {
  /// The one-based index of the line containing the character.
  final int line;

  /// The one-based index of the column containing the character.
  final int column;

  /// Initialize a newly created location to represent the location of the
  /// character at the given [line] and [column].
  CharacterLocation(this.line, this.column);

  @override
  String toString() => '$line:$column';
}

/// Information about line and column information within a source file.
class LineInfo {
  /// A list containing the offsets of the first character of each line in the
  /// source code.
  final List<int> lineStarts;

  /// The zero-based [lineStarts] index resulting from the last call to
  /// [getLocation].
  int _previousLine = 0;

  /// Initialize a newly created set of line information to represent the data
  /// encoded in the given list of [lineStarts].
  LineInfo(this.lineStarts) {
    if (lineStarts.isEmpty) {
      throw ArgumentError('lineStarts must be non-empty');
    }
  }

  /// Initialize a newly created set of line information corresponding to the
  /// given file [content].
  factory LineInfo.fromContent(String content) =>
      LineInfo(util.computeLineStarts(content));

  /// The number of lines.
  int get lineCount => lineStarts.length;

  /// Return the location information for the character at the given [offset].
  CharacterLocation getLocation(int offset) {
    var min = 0;
    var max = lineStarts.length - 1;

    // Subsequent calls to [getLocation] are often for offsets near each other.
    // To take advantage of that, we cache the index of the line start we found
    // when this was last called. If the current offset is on that line or
    // later, we'll skip those early indices completely when searching.
    if (offset >= lineStarts[_previousLine]) {
      min = _previousLine;

      // Before kicking off a full binary search, do a quick check here to see
      // if the new offset is on that exact line.
      if (min == lineStarts.length - 1 || offset < lineStarts[min + 1]) {
        return CharacterLocation(min + 1, offset - lineStarts[min] + 1);
      }
    }

    // Binary search to find the line containing this offset.
    while (min < max) {
      var midpoint = (max - min + 1) ~/ 2 + min;

      if (lineStarts[midpoint] > offset) {
        max = midpoint - 1;
      } else {
        min = midpoint;
      }
    }

    _previousLine = min;

    return CharacterLocation(min + 1, offset - lineStarts[min] + 1);
  }

  /// Return the offset of the first character on the line with the given
  /// [lineNumber].
  int getOffsetOfLine(int lineNumber) {
    if (lineNumber < 0 || lineNumber >= lineCount) {
      throw ArgumentError(
          'Invalid line number: $lineNumber; must be between 0 and ${lineCount - 1}');
    }
    return lineStarts[lineNumber];
  }

  /// Return the offset of the first character on the line following the line
  /// containing the given [offset].
  int getOffsetOfLineAfter(int offset) {
    return getOffsetOfLine(getLocation(offset).line);
  }
}
