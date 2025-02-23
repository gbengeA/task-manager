import 'package:hive_flutter/adapters.dart';
part 'Task.g.dart';
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  Task({required this.id, required this.name, required this.description});
}