const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.goarena.uz/api',
);

const androidStoreUrl = String.fromEnvironment(
  'ANDROID_STORE_URL',
  defaultValue:
      'https://play.google.com/store/apps/details?id=uz.arenago.arenago',
);

const iosStoreUrl = String.fromEnvironment(
  'IOS_STORE_URL',
  defaultValue: 'https://apps.apple.com/search?term=ArenaGo',
);

String resolveApiUrl(String path) {
  if (path.trim().isEmpty) return '';
  final parsed = Uri.tryParse(path);
  if (parsed?.hasScheme == true) return path;
  return Uri.parse(apiBaseUrl).resolve(path).toString();
}
