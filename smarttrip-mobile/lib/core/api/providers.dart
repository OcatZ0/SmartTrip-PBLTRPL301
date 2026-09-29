import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import 'api_client.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});
