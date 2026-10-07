import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/resources/domain/resource_failure.dart';
import 'package:tilmizo_teacher/features/resources/presentation/controllers/resources_providers.dart';
import 'package:tilmizo_teacher/features/resources/presentation/screens/add_resource_screen.dart';
import 'package:tilmizo_teacher/features/resources/presentation/screens/resources_screen.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_resources.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith({
    List<GroupResource> resources = const [],
    bool archived = false,
  }) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    groups: FakeGroupsRepository([
      buildGroup(id: 'group-1', isActive: !archived),
    ]),
    resources: FakeResourcesRepository(resources),
  );

  Future<void> openResources(WidgetTester tester, TestBackend backend) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, ResourcesRoute(groupId: 'group-1'));
    expect(find.byType(ResourcesScreen), findsOneWidget);
  }

  testWidgets('group details opens resources from a dedicated tile', (
    tester,
  ) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backendWith(resources: [buildResource()]));
    await openRoute(tester, GroupDetailsRoute(groupId: 'group-1'));

    expect(find.byKey(const Key('classes-tile')), findsOneWidget);
    expect(find.text('مورد واحد'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('resources-tile')));
    expect(find.byType(ResourcesScreen), findsOneWidget);
  });

  testWidgets('lists resources with live counts and teacher-wide quota', (
    tester,
  ) async {
    await openResources(
      tester,
      backendWith(
        resources: [
          buildResource(id: 'a', title: 'مذكرة'),
          buildResource(
            id: 'b',
            title: 'محاكاة',
            type: ResourceType.externalLink,
            externalUrl: 'https://phet.colorado.edu/sim',
          ),
        ],
      ),
    );

    expect(find.text('مذكرة'), findsOneWidget);
    expect(find.text('محاكاة'), findsOneWidget);
    expect(find.text('phet.colorado.edu'), findsOneWidget);
    expect(find.text('الكل (2)'), findsOneWidget);
    expect(find.text('ملفات ومستندات (1)'), findsOneWidget);
    expect(find.text('روابط (1)'), findsOneWidget);
    expect(
      find.text('المساحة مشتركة بين كل مجموعاتك، وليست خاصة بهذه المجموعة.'),
      findsOneWidget,
    );
    expect(find.text('100 ميجابايت / 1 جيجابايت'), findsOneWidget);
  });

  testWidgets('filters by category and search', (tester) async {
    await openResources(
      tester,
      backendWith(
        resources: [
          buildResource(id: 'a', title: 'مذكرة الباب الأول'),
          buildResource(
            id: 'b',
            title: 'صورة السبورة',
            type: ResourceType.image,
          ),
        ],
      ),
    );

    await tester.ensureVisible(
      find.byKey(const Key('resource-category-images')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resource-category-images')));
    await tester.pumpAndSettle();
    expect(find.text('مذكرة الباب الأول'), findsNothing);
    expect(find.text('صورة السبورة'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('resource-category-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resource-category-all')));
    await tester.enterText(find.byKey(const Key('resources-search')), 'الباب');
    await tester.pumpAndSettle();
    expect(find.text('مذكرة الباب الأول'), findsOneWidget);
    expect(find.text('صورة السبورة'), findsNothing);

    await tester.enterText(find.byKey(const Key('resources-search')), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد موارد مطابقة للبحث أو الفلاتر.'), findsOneWidget);
  });

  testWidgets('shows an empty state when RLS returns no rows', (tester) async {
    await openResources(tester, backendWith());
    expect(find.byKey(const Key('resources-empty')), findsOneWidget);
    expect(find.byKey(const Key('add-resource')), findsOneWidget);
  });

  testWidgets('shows a retryable error when loading fails', (tester) async {
    final backend = backendWith(resources: [buildResource()]);
    backend.resources.fetchFailure = const AppFailure(AppFailureType.network);
    await openResources(tester, backend);

    expect(find.text('تعذّر تحميل الموارد'), findsOneWidget);
    backend.resources.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('مذكرة القوانين'), findsOneWidget);
  });

  testWidgets('archived groups are read-only', (tester) async {
    await openResources(
      tester,
      backendWith(resources: [buildResource()], archived: true),
    );

    expect(
      find.text('هذه المجموعة مؤرشفة، لذا يمكنك عرض مواردها وفتحها فقط.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('add-resource')), findsNothing);
    expect(find.byType(PopupMenuButton<Object>), findsNothing);
    expect(find.byTooltip('خيارات المورد'), findsNothing);
    expect(find.text('معاينة / تنزيل'), findsOneWidget);
  });

  testWidgets('add form is blocked for archived groups', (tester) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backendWith(archived: true));
    await openRoute(tester, AddResourceRoute(groupId: 'group-1', type: 'pdf'));
    expect(find.byKey(const Key('resource-submit')), findsNothing);
  });

  for (final cleanupPending in [false, true]) {
    testWidgets('delete removes the card (cleanup pending: $cleanupPending)', (
      tester,
    ) async {
      final backend = backendWith(resources: [buildResource()]);
      backend.resources.deleteCleanupPending = cleanupPending;
      await openResources(tester, backend);
      final usageFetches = backend.usage.fetches;

      await tester.tap(find.byTooltip('خيارات المورد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(find.text('حذف هذا المورد؟'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-resource-delete')));
      await tester.pumpAndSettle();

      expect(backend.resources.calls, ['delete']);
      expect(find.text('مذكرة القوانين'), findsNothing);
      expect(
        find.text(
          cleanupPending
              ? 'تم حذف المورد. قد يستغرق تحرير المساحة التخزينية بعض الوقت.'
              : 'تم حذف المورد.',
        ),
        findsOneWidget,
      );
      expect(backend.usage.fetches, greaterThan(usageFetches));
      if (cleanupPending) {
        final afterDelete = backend.usage.fetches;
        await tester.pump(storageCleanupRefreshDelay);
        await tester.pumpAndSettle();
        expect(backend.usage.fetches, greaterThan(afterDelete));
      }
    });
  }

  testWidgets('a failed delete keeps the card', (tester) async {
    final backend = backendWith(resources: [buildResource()]);
    backend.resources.writeFailure = const ResourceFailure(
      ResourceFailureReason.groupNotActive,
    );
    await openResources(tester, backend);

    await tester.tap(find.byTooltip('خيارات المورد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-resource-delete')));
    await tester.pumpAndSettle();

    expect(find.text('مذكرة القوانين'), findsOneWidget);
  });

  testWidgets('type picker maps six choices and shows backend limits', (
    tester,
  ) async {
    await openResources(tester, backendWith());
    await tester.tap(find.byKey(const Key('add-resource')));
    await tester.pumpAndSettle();

    for (final type in ResourceType.values) {
      expect(find.byKey(Key('resource-type-${type.backendValue}')), findsOne);
    }
    expect(find.text('حتى 25 ميجابايت'), findsNWidgets(2));
    expect(find.text('حتى 10 ميجابايت'), findsOneWidget);
    expect(find.text('حتى 50 ميجابايت'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resource-type-video_link')));
    await tester.pumpAndSettle();
    expect(find.byType(AddResourceScreen), findsOneWidget);
    expect(find.byKey(const Key('resource-url')), findsOneWidget);
  });

  testWidgets('creates a link only with an HTTPS URL', (tester) async {
    final backend = backendWith();
    await openResources(tester, backend);
    await openRoute(
      tester,
      AddResourceRoute(groupId: 'group-1', type: 'external_link'),
    );

    await tester.enterText(find.byKey(const Key('resource-title')), 'محاكاة');
    await tester.enterText(
      find.byKey(const Key('resource-url')),
      'http://insecure.test',
    );
    await tapVisible(tester, find.byKey(const Key('resource-submit')));
    expect(find.text('أدخل رابطًا صحيحًا يبدأ بـ https://'), findsOneWidget);
    expect(backend.resources.calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('resource-url')),
      'https://phet.colorado.edu',
    );
    await tapVisible(tester, find.byKey(const Key('resource-submit')));

    expect(backend.resources.calls, ['createLink']);
    expect(find.byType(ResourcesScreen), findsOneWidget);
    expect(find.text('محاكاة'), findsOneWidget);
  });

  testWidgets('uploads a file and lists it only after finalize', (
    tester,
  ) async {
    final backend = backendWith();
    await openResources(tester, backend);
    await openRoute(tester, AddResourceRoute(groupId: 'group-1', type: 'pdf'));

    backend.filePicker.next = pickedPdf(size: 26 * mib);
    await tapVisible(tester, find.byKey(const Key('resource-pick-file')));
    expect(
      find.text('حجم الملف أكبر من الحد المسموح (25 ميجابايت).'),
      findsOne,
    );

    backend.filePicker.next = pickedPdf();
    await tapVisible(tester, find.byKey(const Key('resource-pick-file')));
    await tester.enterText(find.byKey(const Key('resource-title')), 'مذكرة');
    await tapVisible(tester, find.byKey(const Key('resource-submit')));

    expect(backend.resources.calls, ['reserve', 'finalize']);
    expect(backend.uploader.uploaded, hasLength(1));
    expect(find.byType(ResourcesScreen), findsOneWidget);
    expect(find.text('مذكرة'), findsOneWidget);
  });

  testWidgets('a failed upload is cancelled and offers retry', (tester) async {
    final backend = backendWith();
    backend.uploader.failure = const ResourceFailure(
      ResourceFailureReason.uploadFailed,
    );
    await openResources(tester, backend);
    await openRoute(tester, AddResourceRoute(groupId: 'group-1', type: 'pdf'));

    backend.filePicker.next = pickedPdf();
    await tapVisible(tester, find.byKey(const Key('resource-pick-file')));
    await tester.enterText(find.byKey(const Key('resource-title')), 'مذكرة');
    await tapVisible(tester, find.byKey(const Key('resource-submit')));

    expect(backend.resources.calls, ['reserve', 'cancel']);
    expect(find.text('تعذّر رفع الملف. حاول مرة أخرى.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    backend.uploader.failure = null;
    await tapVisible(tester, find.byKey(const Key('resource-submit')));
    expect(backend.resources.calls, [
      'reserve',
      'cancel',
      'reserve',
      'finalize',
    ]);
  });

  testWidgets('editing a link preserves its URL and offers no file swap', (
    tester,
  ) async {
    final backend = backendWith(
      resources: [
        buildResource(
          type: ResourceType.videoLink,
          externalUrl: 'https://youtu.be/kept',
          description: 'وصف',
        ),
      ],
    );
    await openResources(tester, backend);
    await openRoute(
      tester,
      EditResourceRoute(groupId: 'group-1', resourceId: 'resource-1'),
    );

    expect(find.text('https://youtu.be/kept'), findsOneWidget);
    expect(find.byKey(const Key('resource-change-type')), findsNothing);
    await tester.enterText(find.byKey(const Key('resource-title')), 'جديد');
    await tapVisible(tester, find.byKey(const Key('resource-submit')));

    expect(backend.resources.lastUpdate, {
      'title': 'جديد',
      'description': 'وصف',
      'session_id': null,
      'url': 'https://youtu.be/kept',
    });
  });

  testWidgets('editing an upload sends no URL and cannot replace the file', (
    tester,
  ) async {
    final backend = backendWith(resources: [buildResource()]);
    await openResources(tester, backend);
    await openRoute(
      tester,
      EditResourceRoute(groupId: 'group-1', resourceId: 'resource-1'),
    );

    expect(find.byKey(const Key('resource-pick-file')), findsNothing);
    expect(
      find.text(
        'لا يمكن استبدال الملف بعد رفعه. لاستبدال المحتوى احذف المورد وأضف موردًا جديدًا.',
      ),
      findsOneWidget,
    );
    await tapVisible(tester, find.byKey(const Key('resource-submit')));
    expect(backend.resources.lastUpdate?['url'], isNull);
  });

  testWidgets('opens uploaded files through the authenticated service', (
    tester,
  ) async {
    final backend = backendWith(resources: [buildResource()]);
    await openResources(tester, backend);

    await tester.tap(find.text('معاينة / تنزيل'));
    await tester.pumpAndSettle();
    expect(backend.files.opened, ['resource-1']);

    backend.files.failure = ResourceFileFailureType.denied;
    await tester.tap(find.text('معاينة / تنزيل'));
    await tester.pumpAndSettle();
    expect(find.text('لم يعد هذا الملف متاحًا.'), findsOneWidget);
  });
}
