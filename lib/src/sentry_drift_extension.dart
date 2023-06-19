import 'package:drift/drift.dart';
import 'package:sentry/sentry.dart';

import 'sentry_executor.dart';
import 'version.dart';

extension SentryDriftExtension on QueryExecutor {
  SentryQueryExecutor addSentry({
    Hub? hub,
  }) {
    hub = hub ?? HubAdapter();

    // ignore: invalid_use_of_internal_member
    final options = hub.options;
    options.sdk.addIntegration('SentryDriftTracing');
    options.sdk.addPackage(packageName, packageVersion);

    return SentryQueryExecutor(this, hub: hub);
  }
}
