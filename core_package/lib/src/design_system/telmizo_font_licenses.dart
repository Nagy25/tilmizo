import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers the SIL Open Font License texts for the bundled typefaces so they
/// appear in the application's license page.
void registerTelmizoFontLicenses() {
  const fonts = {
    'Manrope': 'Manrope-OFL.txt',
    'Plus Jakarta Sans': 'PlusJakartaSans-OFL.txt',
    'IBM Plex Sans Arabic': 'IBMPlexSansArabic-OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final entry in fonts.entries) {
      final text = await rootBundle.loadString(
        'packages/core_package/assets/fonts/${entry.value}',
      );
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
