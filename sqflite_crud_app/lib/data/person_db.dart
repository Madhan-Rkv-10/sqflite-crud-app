import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../model/person.dart';

class PersonDB {
  final _controller = StreamController<List<Person>>.broadcast();
  List<Person> _persons = [];
  Database? _db;
  final String dbName;
  PersonDB({required this.dbName});

  Future<bool> close() async {
    final db = _db;
    if (db == null) {
      return false;
    }
    await db.close();
    return true;
  }

  Future<bool> open() async {
    if (_db != null) {
      return true;
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$dbName';
    try {
      final db = await openDatabase(path);
      _db = db;

      // create the table if it doesn't exist

      const create = '''CREATE TABLE IF NOT EXISTS PEOPLE (
          ID INTEGER PRIMARY KEY AUTOINCREMENT,
          FIRST_NAME STRING NOT NULL,
          LAST_NAME STRING NOT NULL
        )''';

      await db.execute(create);

      // if everything went fine, we then read all the objects
      // and populate the stream

      _persons = await _fetchPeople();
      _controller.add(_persons);
      return true;
    } catch (e) {
      print('error = $e');
      return false;
    }
  }

  Future<List<Person>> _fetchPeople() async {
    final db = _db;
    if (db == null) {
      return [];
    }

    try {
      // read the existing data if any
      final readResult = await db.query(
        'PEOPLE',
        distinct: true,
        columns: ['ID', 'FIRST_NAME', 'LAST_NAME'],
        orderBy: 'ID',
      );

      final people = readResult.map((row) => Person.fromData(row)).toList();
      return people;
    } catch (e) {
      print('error = $e');
      return [];
    }
  }

  Future<bool> delete(Person person) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final deletedCount = await db.delete(
        'PEOPLE',
        where: 'ID = ?',
        whereArgs: [person.id],
      );

      // delete it locally as well

      if (deletedCount == 1) {
        _persons.remove(person);
        _controller.add(_persons);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error inserting $e');
      return false;
    }
  }

  Future<bool> create(String firstName, String lastName) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final id = await db.insert(
        'PEOPLE',
        {
          'FIRST_NAME': firstName,
          'LAST_NAME': lastName,
        },
      );

      final person = Person(id, firstName, lastName);
      _persons.add(person);
      _controller.add(_persons);

      return true;
    } catch (e) {
      print('Error inserting $e');
      return false;
    }
  }

  // uses the person's id to update its first name and last name
  Future<bool> update(Person person) async {
    final db = _db;
    if (db == null) {
      return false;
    }
    try {
      final updatedCount = await db.update(
        'PEOPLE',
        {
          'FIRST_NAME': person.firstName,
          'LAST_NAME': person.lastName,
        },
        where: 'ID = ?',
        whereArgs: [person.id],
      );

      if (updatedCount == 1) {
        _persons.removeWhere((p) => p.id == person.id);
        _persons.add(person);
        _controller.add(_persons);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error inserting $e');
      return false;
    }
  }

  Stream<List<Person>> all() =>
      _controller.stream.map((event) => event..sort());
}
