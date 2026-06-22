// SPDX-License-Identifier: MIT
//
// FEAT-SPEC §8 alignment: re-export the Phase B soft-hyphen mapping helper
// under the production-name alias `HyphenatedText`.
//
// The implementation still lives in `soft_hyphen_mapping.dart` as a
// spike-only helper and is exposed here as an alias only. The class
// itself is not renamed in place so existing Phase B tests continue to
// compile. The alias exists to keep the production naming aligned with
// FEAT-SPEC §8 (`HyphenatedText`) while the debug gate is the only
// caller. No production Paper/PDF reader, vocab/notes flow, or Rust
// integration should consume this symbol directly yet.

import 'soft_hyphen_mapping.dart';

export 'soft_hyphen_mapping.dart'
    show
        SoftHyphenMapping,
        removeSoftHyphens,
        softHyphenTextEditingValue,
        copyRawToClipboard;

/// FEAT-SPEC §8 name for the soft-hyphen mapping helper.
///
/// This is a temporary alias for the Phase B `SoftHyphenMapping` and
/// is debug-gate only. Do not import this from production reader code
/// until the real-device overlay gate has passed and a dedicated
/// production implementation (with dictionary/license gate behind it)
/// has been approved.
typedef HyphenatedText = SoftHyphenMapping;
