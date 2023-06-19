# Drift Sentry

[![CI](https://github.com/utisam/drift_sentry/actions/workflows/ci.yml/badge.svg)](https://github.com/utisam/drift_sentry/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/drift_sentry.svg)](https://pub.dev/packages/drift_sentry)

[Sentry](https://sentry.io/) integration for the [drift](https://pub.dev/packages/drift) package.

## Usage

```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    // Use .addSentry() to wrap QueryExecutor
    return NativeDatabase.createInBackground(file).addSentry();
  });
}
```
