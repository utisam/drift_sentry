import 'package:drift/drift.dart';
import 'package:drift_sentry/drift_sentry.dart';
import 'package:meta/meta.dart';
import 'package:sentry/sentry.dart';

class SentryQueryExecutor<E extends QueryExecutor> implements QueryExecutor {
  @protected
  final E executor;

  @protected
  final ISentrySpan? parentSpan;

  final Hub _hub;

  SentryQueryExecutor(
    this.executor, {
    @internal this.parentSpan,
    @internal Hub? hub,
  }) : _hub = hub ?? HubAdapter();

  @override
  SqlDialect get dialect => executor.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) => executor.ensureOpen(user);

  @override
  Future<void> close() => executor.close();

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _withAsyncChildSpan(() {
        return executor.runInsert(statement, args);
      }, 'db.sql.execute', description: '$statement $args');

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String statement, List<Object?> args) =>
      _withAsyncChildSpan(() {
        return executor.runSelect(statement, args);
      }, 'db.sql.query', description: '$statement $args');

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _withAsyncChildSpan(() {
        return executor.runUpdate(statement, args);
      }, 'db.sql.execute', description: '$statement $args');

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _withAsyncChildSpan(() {
        return executor.runDelete(statement, args);
      }, 'db.sql.execute', description: '$statement $args');

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _withAsyncChildSpan(() {
        return executor.runCustom(statement, args);
      }, 'db.sql.execute', description: '$statement $args');

  @override
  Future<void> runBatched(BatchedStatements statements) {
    final pairs = statements.arguments
        .map((a) => '(${a.statementIndex}, ${a.arguments})')
        .join(', ');

    return _withAsyncChildSpan(() {
      return executor.runBatched(statements);
    }, 'db', description: '${statements.statements}, [$pairs]');
  }

  @override
  TransactionExecutor beginTransaction() {
    final currentSpan = parentSpan ?? _hub.getSpan();
    return SentryTransactionExecutor(
      executor.beginTransaction(),
      parentSpan: currentSpan?.startChild(
        'db.sql.transaction',
        description: 'Begin transaction',
      ),
      hub: _hub,
    );
  }

  Future<T> _withAsyncChildSpan<T>(
    Future<T> Function() fn,
    String operation, {
    String? description,
  }) async {
    final currentSpan = parentSpan ?? _hub.getSpan();
    final span = currentSpan?.startChild(
      operation,
      description: description,
    );

    try {
      final result = await fn();
      span?.status = const SpanStatus.ok();
      return result;
    } catch (exception) {
      span?.throwable = exception;
      span?.status = const SpanStatus.internalError();
      rethrow;
    } finally {
      await span?.finish();
    }
  }
}
