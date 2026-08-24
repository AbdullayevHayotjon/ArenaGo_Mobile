const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://172.29.90.122:8080/api',
);

String resolveApiUrl(String path) {
  if (path.trim().isEmpty) return '';
  final parsed = Uri.tryParse(path);
  if (parsed?.hasScheme == true) return path;
  return Uri.parse(apiBaseUrl).resolve(path).toString();
}
