import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_package/core_package.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

/// Serves every request from a local file and records what was fetched.
final class _FakeCacheManager implements BaseCacheManager {
  _FakeCacheManager(this.bytes);

  final Uint8List bytes;
  final fetched = <({String url, String? key})>[];
  final _files = <String, File>{};

  FileInfo _info(String key) => FileInfo(
    _files[key]!,
    FileSource.Cache,
    DateTime.now().add(const Duration(days: 1)),
    key,
  );

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async => _files.containsKey(key) ? _info(key) : null;

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    fetched.add((url: url, key: key));
    final file = const LocalFileSystem().systemTempDirectory
        .createTempSync('avatar')
        .childFile('avatar');
    await file.writeAsBytes(bytes);
    return _files[key ?? url] = file;
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => _files.containsKey(key ?? url)
      ? Stream.value(_info(key ?? url))
      : const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The resolver does real file I/O, so let it finish outside fake async.
Future<void> _settleResolver(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Widget _avatarApp(_FakeCacheManager cache, Widget child) => ProviderScope(
  overrides: [
    telmizoImageCacheManagerProvider.overrideWithValue(cache),
    telmizoImageResolverProvider.overrideWithValue(
      CachingImageResolver(
        cacheManager: cache,
        createSignedUrl: (bucket, path) async => 'https://signed/$bucket/$path',
        isWeb: false,
      ),
    ),
  ],
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  test('initials use the first and last name words', () {
    expect(profileInitials('ahmed nagy'), 'AN');
    expect(profileInitials('  ahmed mohamed nagy  '), 'AN');
    expect(profileInitials('أحمد ناجي'), 'أن');
    expect(profileInitials('ahmed'), 'A');
    expect(profileInitials(null), '');
  });

  test('detects JPEG, PNG, and WebP signatures', () {
    expect(
      detectProfileAvatarContentType(Uint8List.fromList([0xff, 0xd8, 0xff])),
      'image/jpeg',
    );
    expect(
      detectProfileAvatarContentType(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]),
      ),
      'image/png',
    );
    expect(
      detectProfileAvatarContentType(
        Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
          0x50,
        ]),
      ),
      'image/webp',
    );
  });

  test('rejects unsupported and oversized avatars', () {
    expect(
      () => validateProfileAvatar(Uint8List.fromList([1, 2, 3])),
      throwsA(
        isA<ProfileAvatarFailure>().having(
          (failure) => failure.type,
          'type',
          ProfileAvatarFailureType.unsupportedFormat,
        ),
      ),
    );
    expect(
      () => validateProfileAvatar(Uint8List(profileAvatarMaxBytes + 1)),
      throwsA(
        isA<ProfileAvatarFailure>().having(
          (failure) => failure.type,
          'type',
          ProfileAvatarFailureType.tooLarge,
        ),
      ),
    );
  });

  testWidgets(
    'one-pixel private avatar falls back to initials and keeps edit action',
    (tester) async {
      final cache = _FakeCacheManager(_onePixelPng);
      var edits = 0;
      await tester.runAsync(
        () => tester.pumpWidget(
          _avatarApp(
            cache,
            TelmizoAvatar(
              avatarUrl: 'user-id/avatar',
              fullName: 'ahmed nagy',
              avatarRevision: 'revision-2',
              editTooltip: 'Change photo',
              onEdit: () => edits++,
            ),
          ),
        ),
      );
      await _settleResolver(tester);

      expect(
        cache.fetched.single.url,
        'https://signed/profile-avatars/user-id/avatar',
      );
      expect(
        cache.fetched.single.key,
        'profile-avatars/user-id/avatar@revision-2',
      );
      expect(find.text('AN'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      await tester.tap(find.byTooltip('Change photo'));
      expect(edits, 1);
    },
  );

  testWidgets('missing avatar shows initials', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TelmizoAvatar(fullName: 'ahmed nagy')),
        ),
      ),
    );
    expect(find.text('AN'), findsOneWidget);
  });

  testWidgets('normal private photo loads once through the image cache', (
    tester,
  ) async {
    final data = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 16, 16),
        Paint()..color = Colors.red,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(16, 16);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    expect(data, isNotNull);
    final cache = _FakeCacheManager(data!.buffer.asUint8List());
    const avatar = TelmizoAvatar(
      avatarUrl: 'user-id/avatar',
      fullName: 'ahmed nagy',
      avatarRevision: 'revision-1',
    );

    for (var i = 0; i < 2; i++) {
      await tester.runAsync(() => tester.pumpWidget(_avatarApp(cache, avatar)));
      await _settleResolver(tester);
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.cacheKey, 'profile-avatars/user-id/avatar@revision-1');
      await tester.pumpWidget(const SizedBox());
    }
    expect(cache.fetched, hasLength(1));
  });
}
