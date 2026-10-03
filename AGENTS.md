# Telmizo Project Guidelines

## Repository layout

This root contains three independent, path-linked Flutter projects:

- `tilmizo_teacher`: the teacher application for Android, iOS, and web.
- `tilmizo_student`: the student application for Android and iOS.
- `core_package`: the shared Flutter package used by both applications.

Do not add a root Pub workspace. Both applications must depend on
`core_package` through `path: ../core_package`.

## Architecture and ownership

- Use Flutter 3.47.5 and Dart 3.13.4.
- Organize application code under `lib/app`, `lib/core`, `lib/features`, and
  `lib/router` as needed.
- Organize feature code into `data`, `domain`, and `presentation` layers. Add a
  layer only when it contains meaningful code; do not add placeholder files.
- Put code shared by both applications in `core_package` and export its public
  API through `lib/core_package.dart`.
- Keep application routing, translations, generated localization, and
  application-specific storage inside each application.
- Put reusable app-specific widgets and cross-cutting helpers in that
  application's `lib/core` directory.
- Keep every widget file under 300 lines and split larger widgets.
- Use `LocaleKeys` for every visible UI string.
- Use generated AutoRoute route classes; do not use `NamedRouteDef`.
- Instantiate `AppRouter` once outside widget `build` methods.
- Do not add `dependency_overrides` or manually select package versions. Use
  `flutter pub add` and let Pub resolve compatible stable versions.

## Generation and validation

- After changing translations, regenerate both Easy Localization outputs.
- After changing routes or routable pages, run build_runner and keep generated
  AutoRoute files in the application.
- After an application-only change, run `dart analyze` and relevant tests in
  the modified application.
- After a `core_package` change, run `dart analyze` in `core_package`,
  `tilmizo_teacher`, and `tilmizo_student`, then run relevant package and
  application tests.
- Fix every analyzer error, warning, and test failure before finishing.
