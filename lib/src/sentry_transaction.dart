import 'package:drift/drift.dart';
import 'package:drift_sentry/drift_sentry.dart';
import 'package:meta/meta.dart';
import 'package:sentry/sentry.dart';

class SentryTransactionExecutor extends SentryQueryExecutor<TransactionExecutor>
    implements TransactionExecutor {
  SentryTransactionExecutor(
    super.executor, {
    @internal super.parentSpan,
    @internal super.hub,
  });

  @override
  Future<void> rollback() async {
    try {
      executor.rollback();
    } finally {
      parentSpan?.status = const SpanStatus.aborted();
      await parentSpan?.finish();
    }
  }

  @override
  Future<void> send() async {
    try {
      executor.send();
    } finally {
      parentSpan?.status = const SpanStatus.ok();
      await parentSpan?.finish();
    }
  }

  @override
  bool get supportsNestedTransactions => executor.supportsNestedTransactions;
}
