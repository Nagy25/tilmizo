import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tilmizo_teacher/features/resources/domain/resource_failure.dart';
import 'package:tilmizo_teacher/features/resources/domain/resource_models.dart';
import 'package:tilmizo_teacher/features/resources/domain/resource_upload_flow.dart';
import 'package:tilmizo_teacher/features/resources/domain/resources_repository.dart';

import '../../helpers/fake_resources.dart';

void main() {
  late FakeResourcesRepository repository;
  late FakeContentUploader uploader;
  late ResourceUploadFlow flow;
  late List<UploadPhase> phases;

  setUp(() {
    repository = FakeResourcesRepository();
    uploader = FakeContentUploader();
    flow = ResourceUploadFlow(repository, uploader);
    phases = [];
  });

  Future<GroupResource> run([UploadCancelSignal? cancel]) => flow.run(
    groupId: 'group-1',
    type: ResourceType.pdf,
    file: pickedPdf(),
    details: const ResourceDetails(title: 'Notes'),
    cancel: cancel ?? UploadCancelSignal(),
    onPhase: (phase, _) => phases.add(phase),
  );

  test('reserves, uploads, then finalizes in order', () async {
    final resource = await run();

    expect(repository.calls, ['reserve', 'finalize']);
    expect(uploader.uploaded, hasLength(1));
    expect(phases.first, UploadPhase.reserving);
    expect(phases, contains(UploadPhase.uploading));
    expect(phases.last, UploadPhase.finalizing);
    expect(repository.resources, [resource]);
  });

  test('a failed upload cancels the reservation and is not listed', () async {
    uploader.failure = http.ClientException('offline');

    await expectLater(run(), throwsA(isA<http.ClientException>()));
    expect(repository.calls, ['reserve', 'cancel']);
    expect(repository.resources, isEmpty);
  });

  test('a user cancel cancels the reservation', () async {
    final cancel = UploadCancelSignal()..cancel();

    await expectLater(run(cancel), throwsA(isA<UploadCancelled>()));
    expect(repository.calls, ['reserve', 'cancel']);
    expect(uploader.uploaded, isEmpty);
  });

  test('a rejected reserve uploads nothing and cancels nothing', () async {
    repository.writeFailure = const ResourceFailure(
      ResourceFailureReason.quotaExceeded,
    );

    await expectLater(run(), throwsA(isA<ResourceFailure>()));
    expect(repository.calls, ['reserve']);
    expect(uploader.uploaded, isEmpty);
  });

  test(
    'a lost finalize response is retried with the same reservation',
    () async {
      repository.finalizeFailure = const AppFailure(AppFailureType.network);

      await expectLater(run(), throwsA(isA<AppFailure>()));
      final resource = await run();

      expect(repository.calls, ['reserve', 'finalize', 'finalize']);
      expect(repository.resources, [resource]);
    },
  );

  test('a rejected finalize reserves again on retry', () async {
    repository.finalizeFailure = const ResourceFailure(
      ResourceFailureReason.invalidFileContent,
    );

    await expectLater(run(), throwsA(isA<ResourceFailure>()));
    await run();

    expect(repository.calls, ['reserve', 'finalize', 'reserve', 'finalize']);
    expect(repository.resources, hasLength(1));
  });

  test('abandoning releases an unconfirmed reservation', () async {
    repository.finalizeFailure = const AppFailure(AppFailureType.network);
    await expectLater(run(), throwsA(isA<AppFailure>()));

    await flow.abandon();
    expect(repository.calls.last, 'cancel');
  });
}
