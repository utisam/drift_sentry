import 'package:drift/drift.dart';

part 'database.g.dart';

@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
}

@DriftDatabase(tables: [Products])
class ExampleDatabase extends _$ExampleDatabase {
  ExampleDatabase(QueryExecutor queryExecutor) : super(queryExecutor);

  @override
  int get schemaVersion => 1;
}
