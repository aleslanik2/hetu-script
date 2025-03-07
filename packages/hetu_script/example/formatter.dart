import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/analyzer.dart';
import 'package:hetu_script/parser.dart';

void main() {
  final source = HTSource(r'''
    var i = 42
    var j = 'hi, your number is ${ '#' +     i.toString()   }.'
  ''');
  final parser = HTParser();
  final result = parser.parseSource(source);
  final formatter = HTFormatter();
  formatter.formatSource(result);
  print(result.fullName);
  print('--------------------------------------------------------------------');
  print(result.source.content);
  print('--------------------------------------------------------------------');
}
