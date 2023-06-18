// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_sentry/drift_sentry.dart';
import 'package:sentry/sentry.dart';

import 'database.dart';

const dsn = String.fromEnvironment('dsn');

void main() async {
  await runZonedGuarded(() async {
    await Sentry.init(
      (options) => options
        ..dsn = dsn
        ..tracesSampleRate = 1.0
        ..debug = true,
    );
    await _run();
    exit(0);
  }, (exception, stackTrace) async {
    await Sentry.close();
    stderr.writeln(exception.toString());
    exit(-1);
  });
}

Future<void> _run() async {
  final database = ExampleDatabase(
    SentryQueryExecutor(NativeDatabase.memory()),
  );

  final transaction = Sentry.startTransaction(
    'example-transaction',
    'db',
    bindToScope: true,
  );
  try {
    await database
        .into(database.products)
        .insert(ProductsCompanion.insert(title: 'My product'));

    final allProducts = await database.select(database.products).get();
    print('Products in database: $allProducts');

    transaction.status = const SpanStatus.ok();
  } catch (exception) {
    transaction.throwable = exception;
    transaction.status = const SpanStatus.internalError();
    rethrow;
  } finally {
    await transaction.finish();
  }
}
