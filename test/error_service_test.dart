import 'package:flutter_test/flutter_test.dart';
import 'package:brrk/src/app/error_service.dart';
import 'package:brrk/src/rust/api/models.dart';

void main() {
  group('OcrUserError factories — P1-1 sanitized messages', () {
    test('document error has fixed message', () {
      final error = OcrUserError.document();
      expect(
        error.message,
        'This document cannot be processed. Try another file or capture.',
      );
    });

    test('fileSize error has fixed message', () {
      final error = OcrUserError.fileSize();
      expect(error.message, 'This file is too large for the MVP limit.');
    });

    test('storage error has fixed message — no raw exception detail', () {
      final error = OcrUserError.storage();
      expect(
        error.message,
        'Result could not be saved. Check available storage and retry.',
      );
    });

    test('unknown error has fixed message', () {
      final error = OcrUserError.unknown();
      expect(error.message, 'Something went wrong. Please try again.');
    });

    test('apiKey error provides settings action', () {
      final error = OcrUserError.apiKey(() {});
      expect(error.actionLabel, 'Open Settings');
      expect(error.onAction, isNotNull);
    });

    test('network error provides retry action when callback given', () {
      final error = OcrUserError.network(onRetry: () {});
      expect(error.actionLabel, 'Retry');
      expect(error.onAction, isNotNull);
    });

    test('network error has no action when retry is null', () {
      final error = OcrUserError.network();
      expect(error.actionLabel, isNull);
      expect(error.onAction, isNull);
    });

    test('rate limit error provides retry action', () {
      final error = OcrUserError.rateLimit(onRetry: () {});
      expect(
        error.message,
        'Mistral is rate limiting this key. Please wait and try again.',
      );
      expect(error.actionLabel, 'Retry');
    });

    test('timeout error has fixed message', () {
      final error = OcrUserError.timeout(onRetry: () {});
      expect(error.message, 'Network error. Check your connection and retry.');
    });
  });

  group('ocrErrorToUser — all OcrError variants map to fixed messages', () {
    // All field0 details are discarded in release UI per P1-1.
    test('OcrError_FileSizeError → fixed message', () {
      final err = ocrErrorToUser(
        const OcrError.fileSizeError('raw size detail'),
        () {},
      );
      expect(err.message, 'This file is too large for the MVP limit.');
    });

    test('OcrError_DocumentError → fixed message', () {
      final err = ocrErrorToUser(
        const OcrError.documentError('raw document detail'),
        () {},
      );
      expect(
        err.message,
        'This document cannot be processed. Try another file or capture.',
      );
    });

    test('OcrError_NetworkError → fixed message', () {
      final err = ocrErrorToUser(
        const OcrError.networkError('raw network detail'),
        () {},
      );
      expect(err.message, 'Network error. Check your connection and retry.');
    });

    test('OcrError_StorageError → fixed message', () {
      final err = ocrErrorToUser(
        const OcrError.storageError('raw storage detail'),
        () {},
      );
      expect(
        err.message,
        'Result could not be saved. Check available storage and retry.',
      );
    });

    test('OcrError_UnknownError → fixed message', () {
      final err = ocrErrorToUser(
        const OcrError.unknownError('raw unknown detail'),
        () {},
      );
      expect(err.message, 'Something went wrong. Please try again.');
    });

    test('OcrError_ApiKeyError → Settings CTA', () {
      final err = ocrErrorToUser(const OcrError.apiKeyError(), () {});
      expect(err.actionLabel, 'Open Settings');
    });

    test('OcrError_RateLimitError → retry guidance', () {
      final err = ocrErrorToUser(
        const OcrError.rateLimitError(),
        () {},
        onRetry: () {},
      );
      expect(err.actionLabel, 'Retry');
    });
  });

  group('exceptionToUser — raw exception strings never shown in release', () {
    test('API key exception → Settings CTA', () {
      final err = exceptionToUser(
        Exception('API key not configured'),
        onSettings: () {},
      );
      expect(err.actionLabel, 'Open Settings');
    });

    test('timeout exception → fixed message', () {
      final err = exceptionToUser(Exception('Timeout exceeded'));
      expect(err.message, 'Network error. Check your connection and retry.');
    });

    test('socket exception → fixed message', () {
      final err = exceptionToUser(
        Exception('SocketException: connection refused'),
      );
      expect(err.message, 'Network error. Check your connection and retry.');
    });

    test('unknown exception → fixed message (no raw string shown)', () {
      final err = exceptionToUser(
        Exception('some raw internal error detail that should not be shown'),
      );
      expect(err.message, 'Something went wrong. Please try again.');
    });
  });
}
