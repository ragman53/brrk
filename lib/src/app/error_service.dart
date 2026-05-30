import 'package:flutter/material.dart';
import 'package:brrk/src/rust/api/models.dart';

/// User-facing error: category-based fixed message + optional action button.
///
/// P1-1: Release UI shows fixed messages only. Raw exception strings,
/// local paths, and external body text are never shown to the user.
class OcrUserError {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OcrUserError({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// API key invalid/expired — opens Settings.
  factory OcrUserError.apiKey(VoidCallback onSettings) => OcrUserError(
        message: 'Mistral API key is invalid or expired. Update it in Settings.',
        actionLabel: 'Open Settings',
        onAction: onSettings,
      );

  factory OcrUserError.rateLimit({VoidCallback? onRetry}) => OcrUserError(
        message: 'Mistral is rate limiting this key. Please wait and try again.',
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      );

  /// P1-1: do not expose Rust FileSizeError field0 detail in release UI.
  factory OcrUserError.fileSize() => const OcrUserError(
        message: 'This file is too large for the MVP limit.',
      );

  factory OcrUserError.document() => const OcrUserError(
        message: 'This document cannot be processed. Try another file or capture.',
      );

  factory OcrUserError.network({VoidCallback? onRetry}) => OcrUserError(
        message: 'Network error. Check your connection and retry.',
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      );

  factory OcrUserError.timeout({VoidCallback? onRetry}) => OcrUserError(
        message: 'Network error. Check your connection and retry.',
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      );

  /// P1-1: hide raw storage exception detail; use fixed message.
  factory OcrUserError.storage() => const OcrUserError(
        message: 'Result could not be saved. Check available storage and retry.',
      );

  /// P1-1: hide raw parse error detail; use fixed message.
  factory OcrUserError.parse({VoidCallback? onRetry}) => OcrUserError(
        message: 'Could not parse OCR response. Please try again.',
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      );

  /// P1-1: hide raw unknown error detail; use fixed message.
  factory OcrUserError.unknown({VoidCallback? onRetry}) => OcrUserError(
        message: 'Something went wrong. Please try again.',
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      );

  /// Returns a version of this error with the Settings action wired up.
  OcrUserError withSettings(VoidCallback onSettings) {
    return OcrUserError(
      message: message,
      actionLabel: actionLabel ?? 'Open Settings',
      onAction: onSettings,
    );
  }
}

/// Maps OcrError to OcrUserError. All field0 detail is discarded in release UI.
OcrUserError ocrErrorToUser(
  OcrError err,
  VoidCallback onSettings, {
  VoidCallback? onRetry,
}) {
  return switch (err) {
    OcrError_ApiKeyError() => OcrUserError.apiKey(onSettings),
    OcrError_RateLimitError() => OcrUserError.rateLimit(onRetry: onRetry),
    OcrError_FileSizeError() => OcrUserError.fileSize(),
    OcrError_DocumentError() => OcrUserError.document(),
    OcrError_NetworkError() => OcrUserError.network(onRetry: onRetry),
    OcrError_TimeoutError() => OcrUserError.timeout(onRetry: onRetry),
    OcrError_StorageError() => OcrUserError.storage(),
    OcrError_UnknownError() => OcrUserError.unknown(onRetry: onRetry),
    OcrError_ParseError() => OcrUserError.parse(onRetry: onRetry),
  };
}

/// Creates OcrUserError from a generic Exception.
/// P1-1: raw exception strings are not shown in release UI.
/// Only detectable categories (API key, timeout, network) map to fixed messages.
OcrUserError exceptionToUser(
  Object e, {
  VoidCallback? onSettings,
  VoidCallback? onRetry,
}) {
  final msg = e.toString();
  if (msg.contains('API key') || msg.contains('401') || msg.contains('403')) {
    return onSettings == null
        ? OcrUserError.unknown()
        : OcrUserError.apiKey(onSettings);
  }
  if (msg.contains('timeout') || msg.contains('Timeout')) {
    return OcrUserError.timeout(onRetry: onRetry);
  }
  if (msg.contains('network') ||
      msg.contains('connection') ||
      msg.contains('SocketException')) {
    return OcrUserError.network(onRetry: onRetry);
  }
  return OcrUserError.unknown(onRetry: onRetry);
}

/// Shows an error snackbar with optional action button.
void showOcrError(BuildContext context, OcrUserError err) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(err.message),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 5),
      action: err.actionLabel != null && err.onAction != null
          ? SnackBarAction(
              label: err.actionLabel!,
              textColor: Colors.white,
              onPressed: err.onAction!,
            )
          : null,
    ),
  );
}