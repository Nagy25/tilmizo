import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilmizo_student/features/select_language/data/language_selection_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists whether a language has been selected', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = LanguageSelectionStorage(preferences);

    expect(storage.hasSelectedLanguage, isFalse);

    await storage.setHasSelectedLanguage(true);

    expect(storage.hasSelectedLanguage, isTrue);
  });
}
