import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    fun main {
      var a

      print(a is function)
    }
    ''', invokeFunc: 'main');
}
