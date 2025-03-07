import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class Person {
  static final races = <String>['Caucasian'];
  static String _level = '0';
  static String get level => _level;
  static set level(value) => _level = value;
  static String meaning(int n) => 'The meaning of life is $n';

  String get child => 'Tom';
  String name;
  String race;

  Person([this.name = 'Jimmy', this.race = 'Caucasian']);
  Person.withName(this.name, [this.race = 'Caucasian']);

  void greeting(String tag) {
    print('Hi! $tag');
  }
}

extension PersonBinding on Person {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'name':
        return name;
      case 'race':
        return race;
      case 'greeting':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            greeting(positionalArgs.first);
      case 'child':
        return child;
      default:
        throw HTError.undefined(varName);
    }
  }

  void htAssign(String varName, dynamic varValue) {
    switch (varName) {
      case 'name':
        name = varValue;
        break;
      case 'race':
        race = varValue;
        break;
      default:
        throw HTError.undefined(varName);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case 'Person':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person(positionalArgs[0], positionalArgs[1]);
      case 'Person.withName':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person.withName(positionalArgs[0],
                (positionalArgs.length > 1 ? positionalArgs[1] : 'Caucasion'));
      case 'Person.meaning':
        return (HTEntity entity,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            Person.meaning(positionalArgs[0]);
      case 'Person.level':
        return Person.level;
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue) {
    switch (varName) {
      case 'Person.race':
        throw HTError.immutable(varName);
      case 'Person.level':
        Person.level = varValue;
        break;
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as Person;
    return i.htFetch(varName);
  }

  @override
  void instanceMemberSet(dynamic object, String varName, dynamic varValue) {
    var i = object as Person;
    i.htAssign(varName, varValue);
  }
}

void main() {
  var hetu = Hetu();
  hetu.init(externalClasses: [PersonClassBinding()]);
  hetu.eval('''
      external class Person {
        var race: str
        construct([name: str = 'Jimmy', race: str = 'Caucasian']);
        get child
        static fun meaning(n: num)
        static get level
        static set level (value: str)
        construct withName(name: str, [race: str = 'Caucasian'])
        var name
        fun greeting(tag: str)
      }
      fun main {
        var p1: Person = Person()
        p1.greeting('jimmy')
        print(Person.meaning(42))
        print(typeof p1)
        print(p1.name)
        print(p1.child)
        print('My race is', p1.race)
        p1.race = 'Reptile'
        print('Oh no! My race turned into', p1.race)
        Person.level = '3'
        print(Person.level)

        var p2 = Person.withName('Jimmy')
        print(p2.name)
        p2.name = 'John'
      }
      ''', invokeFunc: 'main');
}
