import 'package:drift/native.dart';
import 'package:drift_sentry/drift_sentry.dart';
import 'package:mockito/mockito.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry/src/sentry_tracer.dart';
import 'package:test/test.dart';

import '../example/database.dart';
import 'mocks/mocks.mocks.dart';

const fakeDsn = 'https://abc@def.ingest.sentry.io/1234567';

void main() {
  late MockHub hub;
  late ExampleDatabase db;
  // ignore: invalid_use_of_internal_member
  late SentryTracer tracer;
  setUp(() {
    hub = MockHub();

    when(hub.options).thenReturn(
      SentryOptions(dsn: fakeDsn)..tracesSampleRate = 1.0,
    );

    final context = SentryTransactionContext('name', 'operation');
    tracer = SentryTracer(context, hub);
    when(hub.getSpan()).thenReturn(tracer);

    db = ExampleDatabase(SentryQueryExecutor(
      NativeDatabase.memory(),
      hub: hub,
    ));
  });
  tearDown(() async {
    await db.close();
  });
  test('Insert', () async {
    await db
        .into(db.products)
        .insert(ProductsCompanion.insert(title: 'Product Name'));

    final span = tracer.children.last;
    expect(span.context.operation, 'db.sql.execute');
    expect(span.context.description,
        'INSERT INTO "products" ("title") VALUES (?) [Product Name]');
    expect(span.status, const SpanStatus.ok());
  });
  test('Select', () async {
    final products = await db.select(db.products).get();
    expect(products, isEmpty);

    final span = tracer.children.last;
    expect(span.context.operation, 'db.sql.query');
    expect(span.context.description, 'SELECT * FROM "products"; []');
    expect(span.status, const SpanStatus.ok());
  });
  test('Update', () async {
    await db
        .update(db.products)
        .write(ProductsCompanion.insert(title: 'Product Name'));

    final span = tracer.children.last;
    expect(span.context.operation, 'db.sql.execute');
    expect(span.context.description,
        'UPDATE "products" SET "title" = ?; [Product Name]');
    expect(span.status, const SpanStatus.ok());
  });
  test('Delete', () async {
    await db.delete(db.products).go();

    final span = tracer.children.last;
    expect(span.context.operation, 'db.sql.execute');
    expect(span.context.description, 'DELETE FROM "products"; []');
    expect(span.status, const SpanStatus.ok());
  });
  test('Transaction', () async {
    await db.transaction(() async {
      await db
          .into(db.products)
          .insert(ProductsCompanion.insert(title: 'Product Name'));
    });

    final span0 = tracer.children[0];
    expect(span0.context.operation, 'db.sql.transaction');
    expect(span0.status, const SpanStatus.ok());

    final span1 = tracer.children[1];
    expect(span1.context.operation, 'db.sql.execute');
    expect(span1.status, const SpanStatus.ok());
  });
  test('Failed transaction', () async {
    await expectLater(db.transaction(() async {
      throw Exception();
    }), throwsA(isException));

    final span0 = tracer.children[0];
    expect(span0.context.operation, 'db.sql.transaction');
    expect(span0.status, const SpanStatus.aborted());
  });
}
