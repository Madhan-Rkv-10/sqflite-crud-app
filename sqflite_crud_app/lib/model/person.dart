class Person implements Comparable {
  final int id;
  final String firstName;
  final String lastName;
  const Person(this.id, this.firstName, this.lastName);

  String get fullName => '$firstName $lastName';

  Person.fromData(Map<String, Object?> data)
      : id = data['ID'] as int,
        firstName = data['FIRST_NAME'] as String,
        lastName = data['LAST_NAME'] as String;

  @override
  int compareTo(covariant Person other) => other.id.compareTo(id);

  @override
  bool operator ==(covariant Person other) => id == other.id;

  @override
  String toString() =>
      'Person, ID = $id, firstName = $firstName, lastName = $lastName';
}
