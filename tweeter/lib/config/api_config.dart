const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://demopg-backend.onrender.com/api',
);

Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$apiBaseUrl$normalizedPath');
}