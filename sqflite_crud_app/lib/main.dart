import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_crud_app/model/person.dart';

import 'data/person_db.dart';
import 'helpers/typedefs.dart';

void main() {
  runApp(const HomePage());
}

class ComposeWidget extends StatefulWidget {
  final OnCompose onCompose;

  const ComposeWidget({super.key, required this.onCompose});

  @override
  State<ComposeWidget> createState() => _ComposeWidgetState();
}

class _ComposeWidgetState extends State<ComposeWidget> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: TextField(
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(
                hintText: 'Enter first name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.purple,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
              ),
              controller: firstNameController,
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          SizedBox(
            height: 50,
            child: TextField(
              style: const TextStyle(
                fontSize: 24,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter last name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
              ),
              controller: lastNameController,
            ),
          ),
          TextButton(
            onPressed: () {
              final firstName = firstNameController.text;
              final lastName = lastNameController.text;
              widget.onCompose(firstName, lastName);
            },
            child: const Text(
              'Add to list',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PersonDB _crudStorage;

  @override
  void initState() {
    _crudStorage = PersonDB(dbName: 'db.sqlite');
    _crudStorage.open();
    super.initState();
  }

  @override
  void dispose() {
    _crudStorage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SQLite in Flutter'),
        ),
        body: StreamBuilder(
          stream: _crudStorage.all(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.active:
              case ConnectionState.waiting:
                if (snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final people = snapshot.data as List<Person>;
                return Column(
                  children: [
                    ComposeWidget(
                      onCompose: (firstName, lastName) async {
                        await _crudStorage.create(firstName, lastName);
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: people.length,
                        itemBuilder: (context, index) {
                          final person = people[index];
                          return ListTile(
                            onTap: () async {
                              final update =
                                  await showUpdateDialog(context, person);
                              if (update == null) {
                                return;
                              }
                              await _crudStorage.update(update);
                            },
                            title: Text(
                              person.fullName,
                              style: const TextStyle(fontSize: 24),
                            ),
                            subtitle: Text(
                              'ID: ${person.id}',
                              style: const TextStyle(fontSize: 18),
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                final shouldDelete =
                                    await showDeleteDialog(context);
                                if (shouldDelete) {
                                  await _crudStorage.delete(person);
                                }
                              },
                              child: const Icon(
                                Icons.disabled_by_default_rounded,
                                color: Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              default:
                return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

final firstNameController = TextEditingController();
final lastNameController = TextEditingController();

Future<Person?> showUpdateDialog(BuildContext context, Person person) {
  firstNameController.text = person.firstName;
  lastNameController.text = person.lastName;
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your udpated values here:'),
            TextField(controller: firstNameController),
            TextField(controller: lastNameController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newPerson = Person(
                person.id,
                firstNameController.text,
                lastNameController.text,
              );
              Navigator.of(context).pop(newPerson);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).then((value) {
    if (value is Person) {
      return value;
    } else {
      return null;
    }
  });
}

Future<bool> showDeleteDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  ).then(
    (value) {
      if (value is bool) {
        return value;
      } else {
        return false;
      }
    },
  );
}
