import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAvatarService implements ProfileAvatarService {
  _FakeAvatarService({this.bytes});

  final Uint8List? bytes;
  String? downloadedPath;
  String? cacheNonce;

  @override
  Future<Uint8List> download(String path, {String? cacheNonce}) async {
    downloadedPath = path;
    this.cacheNonce = cacheNonce;
    return bytes ??
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        );
  }

  @override
  Future<ProfileAvatarUpdate> uploadOwnAvatar(PickedProfileAvatar avatar) =>
      throw UnimplementedError();
}

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
      final service = _FakeAvatarService();
      var edits = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileAvatarServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            home: Scaffold(
              body: TelmizoAvatar(
                avatarUrl: 'user-id/avatar',
                fullName: 'ahmed nagy',
                avatarRevision: 'revision-2',
                editTooltip: 'Change photo',
                onEdit: () => edits++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(service.downloadedPath, 'user-id/avatar');
      expect(service.cacheNonce, 'revision-2');
      expect(find.text('AN'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
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

  testWidgets('normal private photo renders', (tester) async {
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
    final service = _FakeAvatarService(bytes: data!.buffer.asUint8List());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileAvatarServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: Scaffold(
            body: TelmizoAvatar(
              avatarUrl: 'user-id/avatar',
              fullName: 'ahmed nagy',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('AN'), findsNothing);
  });
}
