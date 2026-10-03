import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether [error] represents a connectivity failure rather than a server
/// response. Supabase clients surface offline requests as HTTP client
/// exceptions or, for Auth, as retryable fetch exceptions without a status.
bool isNetworkError(Object error) {
  return error is http.ClientException ||
      error is TimeoutException ||
      (error is AuthRetryableFetchException && error.statusCode == null);
}
