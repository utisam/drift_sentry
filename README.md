# Drift Sentry

[Sentry](https://sentry.io/) integration for the [drift](https://pub.dev/packages/drift) package.

## Usage

Wrap `QueryExecutor` in `SentryQueryExecutor`.

```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return SentryQueryExecutor(NativeDatabase.createInBackground(file));
  });
}
```
