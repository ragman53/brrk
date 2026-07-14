# Privacy Notice

Brrk is a local-first Android application with no Brrk-operated server in this release.
This document explains how your data is handled.

## What Brrk does with your data

### Mistral API Key

Your Mistral API key is stored locally in Android's secure storage (encrypted keystore).
It is sent only to Mistral's OCR service when you explicitly start an OCR operation.
It is never transmitted to any Brrk-controlled server.

### Documents and Images

When you use the paper book capture or PDF import feature, the selected images or PDF
are sent directly to Mistral's OCR API using your API key.
Brrk does not store or log the full content of these documents except as described below.

### Local Storage

Extracted Markdown text, page labels, notes, tags, and imported PDF metadata are stored
in app-private local storage on your device. This data is not accessible to other
applications or cloud backup services (Android full-data backup is disabled).

Captured page images and intermediate OCR cache entries are stored in app-private
directories and are deleted when you delete the corresponding book, page, or PDF.

### No Brrk Server

Brrk has no backend server, no cloud sync, and no analytics services in this release.
All processing — storage, cache, and OCR — happens locally on your device and
directly between your device and Mistral's API.

## What Brrk does NOT do

- Brrk does not collect, transmit, or store your API key on any external server.
- Brrk does not include analytics, crash reporting, or telemetry in this release.
- Brrk does not back up app data to Android cloud backup.
- Brrk does not share your documents or OCR results with any third party other than
  Mistral (as your direct agent when you initiate OCR).

## Mistral OCR

Brrk uses Mistral's OCR API as your BYOK (Bring Your Own Key) service.
Mistral's privacy policy and terms of service apply to your use of their API.
You are responsible for any charges incurred through your Mistral account.

## Data Deletion

Uninstalling the app removes all app-private data, including notes, OCR cache,
and captured images. Brrk does not retain any data after uninstall.

## Changes to This Notice

If this privacy notice changes, the updated version will be reflected in this file
in the repository. For a deployed app, check the repository for the current notice.

## Contact

For privacy concerns, bug reports, or data deletion questions:

- Open a GitHub issue: https://github.com/ragman53/brrk/issues
- Email: see GitHub profile for contact options

Include "Privacy" in the issue title.