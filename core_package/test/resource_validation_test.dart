import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

const _limits = ResourceUploadLimits(
  pdfFileMaxBytes: 26214400,
  imageMaxBytes: 10485760,
  videoMaxBytes: 52428800,
  remainingBytes: 1073741824,
);

ResourceFileProblem? _validate(
  ResourceType type,
  String name,
  int size, {
  String? mime,
  ResourceUploadLimits limits = _limits,
}) => validateResourceFile(
  type: type,
  fileName: name,
  mimeType: mime ?? mimeTypeForFileName(name),
  sizeBytes: size,
  limits: limits,
);

void main() {
  group('isValidHttpsUrl', () {
    test('accepts HTTPS URLs with a host', () {
      expect(isValidHttpsUrl('https://example.com'), isTrue);
      expect(isValidHttpsUrl('https://youtu.be/abc?t=10'), isTrue);
    });

    test('rejects other schemes, whitespace, blanks and long URLs', () {
      expect(isValidHttpsUrl(null), isFalse);
      expect(isValidHttpsUrl(''), isFalse);
      expect(isValidHttpsUrl('http://example.com'), isFalse);
      expect(isValidHttpsUrl('HTTPS://example.com'), isFalse);
      expect(isValidHttpsUrl('javascript:alert(1)'), isFalse);
      expect(isValidHttpsUrl('https://exa mple.com'), isFalse);
      expect(isValidHttpsUrl('https://'), isFalse);
      expect(isValidHttpsUrl('https:///path'), isFalse);
      final long = 'https://example.com/${'a' * 2048}';
      expect(isValidHttpsUrl(long), isFalse);
    });

    test('accepts exactly the maximum length', () {
      const prefix = 'https://example.com/';
      final url = '$prefix${'a' * (resourceUrlMaxLength - prefix.length)}';
      expect(url.length, resourceUrlMaxLength);
      expect(isValidHttpsUrl(url), isTrue);
    });
  });

  group('validateResourceFile', () {
    test('accepts files exactly at each backend limit', () {
      expect(_validate(ResourceType.pdf, 'a.pdf', 26214400), isNull);
      expect(_validate(ResourceType.file, 'a.docx', 26214400), isNull);
      expect(_validate(ResourceType.image, 'a.png', 10485760), isNull);
      expect(_validate(ResourceType.uploadedVideo, 'a.mp4', 52428800), isNull);
    });

    test('rejects files one byte above each backend limit', () {
      expect(
        _validate(ResourceType.pdf, 'a.pdf', 26214401),
        ResourceFileProblem.tooLarge,
      );
      expect(
        _validate(ResourceType.file, 'a.zip', 26214401),
        ResourceFileProblem.tooLarge,
      );
      expect(
        _validate(ResourceType.image, 'a.jpg', 10485761),
        ResourceFileProblem.tooLarge,
      );
      expect(
        _validate(ResourceType.uploadedVideo, 'a.mp4', 52428801),
        ResourceFileProblem.tooLarge,
      );
    });

    test('uses limits supplied by the backend', () {
      const smaller = ResourceUploadLimits(
        pdfFileMaxBytes: 100,
        imageMaxBytes: 100,
        videoMaxBytes: 100,
        remainingBytes: 1000,
      );
      expect(
        _validate(ResourceType.pdf, 'a.pdf', 101, limits: smaller),
        ResourceFileProblem.tooLarge,
      );
    });

    test('rejects files above the remaining teacher quota', () {
      const nearlyFull = ResourceUploadLimits(
        pdfFileMaxBytes: 26214400,
        imageMaxBytes: 10485760,
        videoMaxBytes: 52428800,
        remainingBytes: 999,
      );
      expect(
        _validate(ResourceType.pdf, 'a.pdf', 1000, limits: nearlyFull),
        ResourceFileProblem.quotaExceeded,
      );
    });

    test('mirrors the backend format rules', () {
      expect(
        _validate(ResourceType.pdf, 'a.docx', 10),
        ResourceFileProblem.wrongFormat,
      );
      expect(
        _validate(ResourceType.uploadedVideo, 'a.mov', 10),
        ResourceFileProblem.wrongFormat,
      );
      expect(
        _validate(ResourceType.image, 'a.pdf', 10),
        ResourceFileProblem.wrongFormat,
      );
      expect(_validate(ResourceType.pdf, 'A.PDF', 10), isNull);
    });

    test('rejects empty files and over-long names', () {
      expect(
        _validate(ResourceType.file, 'a.txt', 0),
        ResourceFileProblem.empty,
      );
      expect(
        _validate(ResourceType.file, '${'a' * 252}.txt', 10),
        ResourceFileProblem.nameTooLong,
      );
    });
  });

  test('infers MIME types from file names', () {
    expect(mimeTypeForFileName('Notes.PDF'), 'application/pdf');
    expect(mimeTypeForFileName('clip.mp4'), 'video/mp4');
    expect(mimeTypeForFileName('board.jpeg'), 'image/jpeg');
    expect(mimeTypeForFileName('archive'), 'application/octet-stream');
  });

  test('maps upload limits by type', () {
    expect(_limits.maxBytesFor(ResourceType.file), 26214400);
    expect(_limits.maxBytesFor(ResourceType.videoLink), isNull);
  });
}
