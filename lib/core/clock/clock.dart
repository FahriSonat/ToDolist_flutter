/// Domain koduna dağılmış DateTime.now() kullanımını önlemek için Clock arayüzü (Skill.md)
abstract class Clock {
  DateTime now();
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
