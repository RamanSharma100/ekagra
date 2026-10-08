export 'productivity_datasource.dart';

import 'productivity_datasource.dart';

/// Legacy alias provided for backward compatibility.
/// Prefer injecting [ProductivityDataSource] or [LocalProductivityDataSource].
@Deprecated('Use LocalProductivityDataSource or ProductivityDataSource instead')
typedef MockProductivityDataSource = LocalProductivityDataSource;

