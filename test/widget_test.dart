import 'package:flutter_test/flutter_test.dart';

import 'package:arenago/l10n/app_strings.dart';

void main() {
  test('translations contain core login labels', () {
    expect(AppStrings('uz').t('login'), 'Kirish');
    expect(AppStrings('ru').t('login'), 'Войти');
  });
}
