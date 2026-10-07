import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row([Map<String, dynamic> overrides = const {}]) => {
  'id': 'r1',
  'group_id': 'g1',
  'teacher_id': 't1',
  'session_id': 's1',
  'title': 'Notes',
  'description': 'Read before class',
  'type': 'pdf',
  'storage_path': 't1/g1/r1.pdf',
  'file_name': 'notes.pdf',
  'file_size': 4404019,
  'mime_type': 'application/pdf',
  'external_url': null,
  'created_at': '2026-10-05T10:00:00Z',
  'updated_at': '2026-10-05T11:00:00Z',
  ...overrides,
};

void main() {
  test('parses an uploaded resource row', () {
    final resource = GroupResource.fromRow(_row());

    expect(resource.id, 'r1');
    expect(resource.groupId, 'g1');
    expect(resource.teacherId, 't1');
    expect(resource.sessionId, 's1');
    expect(resource.type, ResourceType.pdf);
    expect(resource.storagePath, 't1/g1/r1.pdf');
    expect(resource.fileSize, 4404019);
    expect(resource.mimeType, 'application/pdf');
    expect(resource.externalUrl, isNull);
    expect(resource.createdAt, DateTime.utc(2026, 10, 5, 10));
    expect(resource.updatedAt, DateTime.utc(2026, 10, 5, 11));
  });

  test('parses a link row with null file columns', () {
    final resource = GroupResource.fromRow(
      _row({
        'type': 'external_link',
        'session_id': null,
        'description': null,
        'storage_path': null,
        'file_name': null,
        'file_size': null,
        'mime_type': null,
        'external_url': 'https://phet.colorado.edu/sim',
      }),
    );

    expect(resource.type, ResourceType.externalLink);
    expect(resource.sessionId, isNull);
    expect(resource.fileSize, isNull);
    expect(resource.linkHost, 'phet.colorado.edu');
  });

  test('rejects rows with missing columns or unknown types', () {
    expect(
      () => GroupResource.fromRow(_row({'title': null})),
      throwsFormatException,
    );
    expect(
      () => GroupResource.fromRow(_row({'type': 'audio'})),
      throwsFormatException,
    );
  });

  test('splits byte sizes into display units', () {
    expect(splitByteSize(512), (value: '512', unit: ByteUnit.bytes));
    expect(splitByteSize(1024), (value: '1', unit: ByteUnit.kilobytes));
    expect(splitByteSize(4404019), (value: '4.2', unit: ByteUnit.megabytes));
    expect(splitByteSize(1073741824), (value: '1', unit: ByteUnit.gigabytes));
  });
}
